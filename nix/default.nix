{
  static ? false,
  stdenv,
  nix-filter,
  ocaml,
  dune,
  findlib,
  tls,
  cohttp,
  cohttp-lwt-unix,
  lwt,
  yojson,
  ppx_deriving_yojson,
  re,
  alcotest,
}:
stdenv.mkDerivation {
  name = "okrs-hook";

  src = with nix-filter.lib;
    filter {
      root = ../.;
      include = [
        "src"
        "scripts"
        "hook.opam"
        ".ocamlformat"
        "dune-project"
      ];
    };

  nativeBuildInputs = [ocaml dune findlib];

  buildInputs = [
    tls
    cohttp
    cohttp-lwt-unix
    lwt
    yojson
    ppx_deriving_yojson
    re
  ];

  checkInputs = [
    alcotest
  ];

  buildPhase = ''
    runHook preBuild

    echo "running ${
      if static
      then "static"
      else "release"
    } build"
    dune build ./src/main.exe --display=short --profile=${
      if static
      then "static"
      else "release"
    }

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin
    cp _build/default/src/main.exe $out/bin/commit-msg.exe
    cp ./scripts/commit-msg $out/bin/commit-msg

    runHook postInstall
  '';

  checkPhase = ''
    runHook preCheck

    dune build @runtest -p hook

    runHook postCheck
  '';
}
