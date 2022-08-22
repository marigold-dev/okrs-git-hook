(lang dune 3.4)

(name marigold-dashboard)

(version 0.2.0)

(maintainers "contact@marigold.dev")

(generate_opam_files true)

(package
 (name hook)
 (synopsis "Git hook for dashboard")
 (description "Git hook for dashboard")
 (depends
  (alcotest :with-test)
  (dune
   (and
    :build
    (>= 3.4.1)))
  (tls
   (>= 0.15.3))
  (cohttp
   (>= 5.0.0))
  (cohttp-lwt-unix
   (>= 5.0.0))
  (lwt
   (>= 5.6.1))
  (yojson
   (>= 2.0.2))
  (ppx_deriving_yojson
   (>= 3.6.1))))

(package
 (name dev)
 (synopsis "Dev package")
 (description "Dev package")
 (allow_empty)
 (depends
  (ocamlformat
   (>= 0.21.0))
  (ocamlformat-rpc
   (>= 0.21.0))
  (ocaml-lsp-server
   (>= 1.13.1))))
