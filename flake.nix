{
  description = "A git hook to work with OKRs organisation ";

  nixConfig = {
    extra-substituters = "https://anmonteiro.nix-cache.workers.dev";
    extra-trusted-public-keys = "ocaml.nix-cache.com-1:/xI2h2+56rwFfKyyFVbkJSeGqSIYMC/Je+7XXqGKDIY=";
  };

  inputs = {
    nixpkgs.url = "github:nix-ocaml/nix-overlays";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nix-filter,
    pre-commit-hooks,
  }:
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.default = pkgs.ocamlPackages.callPackage ./nix {inherit nix-filter;};

      devShells.default = pkgs.mkShell {
        shellHook = ''
          ${self.checks.${system}.pre-commit-check.shellHook}
          echo "https://api.dashboard.marigold.dev/api/objectives" > .git/hooks/.config
        '';
        inputsFrom = [self.packages.${system}.default];

        packages = with pkgs;
        with ocamlPackages; [
          alejandra
          ocaml-lsp
          ocamlformat
          dune
          odoc
        ];
      };

      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            okr = {
              enable = true;
              name = "OKR";
              entry = "${self.packages.${system}.default}/bin/commit-msg";
              language = "script";
              raw.args = [".git/hooks/tmp"];

              pass_filenames = false;
            };
          };
        };
      };
    });
}
