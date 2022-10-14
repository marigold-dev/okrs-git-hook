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
  objective : string;
  krs : kr list;
}
[@@deriving yojson]

type objectives = objective list [@@deriving yojson]

module Cache = struct
  module Map = Map.Make (String)

  let data = ref Map.empty
  let add ~branch ~issue = data := Map.add branch issue !data
  let get ~branch = Map.find_opt branch !data

  let serialize data =
    let data =
      Map.to_seq data
      |> List.of_seq
      |> List.map (fun (key, value) -> (key, `Int value))
    in
    `Assoc data |> Yojson.Basic.to_string

  let deserialize str =
    Yojson.Basic.from_string str
    |> Yojson.Basic.Util.to_assoc
    |> List.map (fun (key, value) -> (key, Yojson.Basic.Util.to_int value))
    |> List.to_seq
    |> Map.of_seq

  let save ~path =
    let file = open_out path in
    serialize !data |> output_string file;
    close_out file

  let load ~path =
    let file =
      try open_in path
      with _ ->
        let file = open_out path in
        output_string file "{}";
        close_out file;
        open_in path
    in
    data := In_channel.input_all file |> deserialize;
    close_in file
end

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

  let check_if_empty ~text ~repo_name ~exit_code list =
    if List.length list = 0 then
      let () = print_endline "" in
      let () =
        Printf.sprintf "No %s found for project: %s" text repo_name
        |> print_endline
      in
      let _ = exit exit_code in
      ()

  let head_re =
    Re.(
      seq
        [
          str "ref: refs/heads/";
          alt [rg 'a' 'z'; rg 'A' 'Z'; char '_'; char '-'; char '/'; char '.']
          |> rep1
          |> group;
        ]
      |> compile)

  let get_current_branch ~git_path =
    let ( >>= ) = Option.bind in
    let file = open_in (Printf.sprintf "%s/HEAD" git_path) in
    let head = In_channel.input_all file in
    close_in file;

    ( List.nth_opt (Re.all head_re head) 0 >>= fun group ->
      Re.Group.get_opt group 1 )
    >>= fun branch ->
    if branch = "main" || branch = "master" then None else Some branch
end

open Utils

let dot_git_path =
  Printf.sprintf "%s/.git" @@ Sys.getcwd ()

let config_path = Printf.sprintf "%s/hooks/.config" dot_git_path
let cache_path = Printf.sprintf "%s/.okr-hook-cache.json" dot_git_path

let repo_name_pcre =
  Re.Pcre.re "(git@|https:\/\/)[a-z\.]+|[:\/]([a-z-_]+)\/([a-z\-]+)\.git"
  |> Re.compile

let repo_name =
  let file = open_in (Printf.sprintf "%s/config" dot_git_path) in
  let content = In_channel.input_all file in
  close_in file;
  match
    Option.bind
      (List.nth_opt (Re.all repo_name_pcre content) 0)
      (fun group -> Re.Group.get_opt group 1)
  with
  | Some repo_name ->
    let splitted = repo_name |> String.split_on_char '\n' in
    List.nth splitted 0
  | None -> failwith "Couldn't find the repo url at .git/config"

let url =
  let file =
    try open_in config_path
    with _ ->
      Printf.sprintf "Couldn't find the config file with the url at %s"
        config_path
      |> prerr_endline;
      exit 1
  in
  let url = file |> input_line in
  close_in file;
  (if String.get url (String.length url - 1) = '/' then url ^ repo_name
  else Printf.sprintf "%s/%s" url repo_name)
  |> Uri.of_string

let fetch () =
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
    >|= (fun json ->
          objectives_of_yojson json
          |> Result.map_error (fun _ ->
                 Printf.sprintf
                   "Couldn't parse the api response. Check if %s response is \
                    valid"
                   (Uri.to_string url)))
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
      exit 1
    else ()
  in
  Result.get_ok response

let prompt objectives =
  let () =
    check_if_empty ~text:"objectives" ~repo_name ~exit_code:0 objectives
  in
  let objective =
    choose ~choice_txt:"objective"
      (fun { objective; _ } -> objective)
      objectives
  in
  let () = check_if_empty ~text:"KRs" ~repo_name ~exit_code:1 objective.krs in

  choose ~choice_txt:"kr" (fun { result; _ } -> result) objective.krs

let () =
  Cache.load ~path:cache_path;
  let () =
    if Array.length Sys.argv < 2 then failwith "Missing temp path in arguments"
    else ()
  in
  let run () = (fetch () |> prompt).issue_number in
  let issue_number =
    match get_current_branch ~git_path:dot_git_path with
    | Some branch -> (
      match Cache.get ~branch with
      | Some issue -> issue
      | None ->
        let issue = run () in
        Cache.add ~branch ~issue;
        Cache.save ~path:cache_path;
        issue)
    | None -> run ()
  in
  let file = open_out_gen [Open_append] 0o666 Sys.argv.(1) in
  Printf.fprintf file " #%i" issue_number;
  close_out file
