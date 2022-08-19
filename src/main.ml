open Lwt_result.Infix
open Cohttp_lwt_unix

type kr = {
  id : int;
  result : string;
  issue_number : int;
}
[@@deriving yojson]

type objective = {
  id : int;
  description : string;
  krs : kr list;
}
[@@deriving yojson]

type objectives = objective list [@@deriving yojson]

module Utils = struct
  let read_index len =
    match read_int_opt () with
    | Some i -> i
    | None ->
      if len = 1 then 0 else raise (Invalid_argument "Argument wasn't an int")

  let choose ~choice_txt map list =
    print_endline "";
    list
    |> List.map map
    |> List.iteri (fun i str ->
           Printf.sprintf "[%i] - %s" i str |> print_endline);
    print_endline "";
    choice_txt
    |> Printf.sprintf "Choose the %s you're working on (-1 if none): "
    |> print_string;
    list |> List.length |> read_index |> List.nth list
end

open Utils

let config_path =
  let reg = Str.regexp_string Filename.dir_sep in
  let splitted = Str.split reg Sys.argv.(0) in
  List.filteri (fun i _ -> i <> List.length splitted - 1) splitted
  |> String.concat Filename.dir_sep
  |> Printf.sprintf "%s/.config"

let repo_name_re =
  Re.(
    seq
      [
        str "https://";
        Re.any |> rep1 |> non_greedy;
        char '/';
        Re.any |> rep1 |> non_greedy;
        char '/';
        any |> rep1 |> group;
      ]
    |> compile)

let repo_name =
  let reg = Str.regexp_string Filename.dir_sep in
  let splitted = Str.split reg Sys.argv.(0) in
  let git_dir =
    List.filteri
      (fun i _ ->
        i <> List.length splitted - 1 && i <> List.length splitted - 2)
      splitted
    |> String.concat Filename.dir_sep
  in
  let file = open_in (Printf.sprintf "%s/config" git_dir) in
  let content = In_channel.input_all file in
  close_in file;
  match
    Option.bind
      (List.nth_opt (Re.all repo_name_re content) 0)
      (fun group -> Re.Group.get_opt group 1)
  with
  | Some repo_name ->
    let splitted = repo_name |> String.split_on_char '\n' in
    List.nth splitted 0
  | None -> failwith "Couldn't find the repo url at .git/config"

let url =
  let file = open_in config_path in
  let url = file |> input_line in
  close_in file;
  (if String.get url (String.length url - 1) = '/' then url ^ repo_name
  else Printf.sprintf "%s/%s" url repo_name)
  |> Uri.of_string

let () =
  let () =
    if Array.length Sys.argv < 2 then failwith "Missing temp path in arguments"
    else ()
  in
  let response =
    url
    |> Client.get
    |> Lwt_result.ok
    >>= (fun (response, body) ->
          let status = response |> Response.status in
          if status |> Cohttp.Code.code_of_status |> Cohttp.Code.is_error then
            status
            |> Cohttp.Code.string_of_status
            |> Printf.sprintf "Got error when fetching api: %s"
            |> Lwt_result.fail
          else body |> Cohttp_lwt.Body.to_string |> Lwt_result.ok)
    >|= Yojson.Safe.from_string
    >|= objectives_of_yojson
    >>= Lwt_result.lift
    |> Lwt_main.run
  in
  let () =
    if Result.is_error response then
      let () =
        response
        |> Result.get_error
        |> Printf.sprintf "Error: %s"
        |> prerr_endline
      in
      let _ = exit 1 in
      ()
    else ()
  in
  let objectives = Result.get_ok response in

  let () =
    if List.length objectives = 0 then
      let () = print_endline "" in
      let () =
        Printf.sprintf "No objective found for project: %s" repo_name
        |> print_endline
      in
      let _ = exit 0 in
      ()
  in
  let objective =
    choose ~choice_txt:"objective"
      (fun { description; _ } -> description)
      objectives
  in
  let kr =
    choose ~choice_txt:"kr" (fun { result; _ } -> result) objective.krs
  in
  let file = open_out_gen [Open_append] 0o666 Sys.argv.(1) in
  Printf.fprintf file " #%i" kr.issue_number;
  close_out file
