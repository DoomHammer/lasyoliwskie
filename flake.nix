{
  description = "Lasy Oliwskie";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05-small";
    flake-utils.url = "github:numtide/flake-utils";

    flake-parts = {
      type = "github";
      owner = "hercules-ci";
      repo = "flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # this adds pre commit hooks via nix to our repo
    git-hooks = {
      type = "github";
      owner = "cachix";
      repo = "git-hooks.nix";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "";
        flake-compat.follows = "";
      };
    };

    flake-checker = {
      type = "github";
      owner = "DeterminateSystems";
      repo = "flake-checker";
    };

    # a tree-wide formatter
    treefmt-nix = {
      type = "github";
      owner = "numtide";
      repo = "treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      imports = with inputs; [
        git-hooks.flakeModule
        treefmt-nix.flakeModule
      ];

      perSystem =
        {
          pkgs,
          lib,
          config,
          system,
          ...
        }:
        let
          #
          # don't check these
          excludes = [ "flake.lock" ];

          mkHook =
            prev:
            lib.attrsets.recursiveUpdate {
              inherit excludes;
              enable = true;
              fail_fast = true;
              verbose = true;
            } prev;
        in
        with pkgs;
        {
          devShells.default = mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = [
              self.checks.${system}.pre-commit-check.enabledPackages
              circup
            ];
          };

          checks = {
            pre-commit-check = inputs.git-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                # make sure our nix code is of good quality before we commit
                statix = mkHook { };
                deadnix = mkHook { };
                flake-checker = mkHook { package = inputs.flake-checker.packages.${system}.flake-checker; };

                # ensure we have nice formatting
                treefmt = mkHook { package = config.treefmt.build.wrapper; };

                # Git police
                check-merge-conflicts = mkHook { };
                commitizen = mkHook { };

                # Various Artists
                check-added-large-files = mkHook { };
                check-case-conflicts = mkHook { };
                detect-private-keys = mkHook { };
                fix-byte-order-marker = mkHook { };
                mixed-line-endings = mkHook { };
              };
            };
          };
          treefmt = {
            projectRootFile = "flake.nix";

            programs = {
              actionlint = {
                enable = true;
              };
              ruff-format = {
                enable = true;
              };
              ruff-check = {
                enable = true;
              };
              deadnix = {
                enable = true;
              };
              dos2unix = {
                enable = true;
              };
              mdformat = {
                enable = true;
              };
              nixfmt = {
                enable = true;
              };
            };
            settings.formatter = {
              dos2unix = {
                excludes = [ "docs/img*" ];
              };
            };
          };
        };
    };
}
