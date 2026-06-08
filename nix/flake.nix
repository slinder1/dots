{
  description = "scott's dots";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    easy-hosts.url = "github:tgirlcloud/easy-hosts";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      easy-hosts,
      home-manager,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        easy-hosts.flakeModule
        ./modules/flake/package-lists.nix
      ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          self',
          inputs',
          system,
          ...
        }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          _module.args.pkgs = pkgs;
          package-lists = {
            core = with pkgs; [
              atuin
              bat
              bob-nvim
              ccache
              coreutils
              delta
              fd
              fzf
              gh
              git
              ov
              ripgrep
              starship
              uv
              xxd
            ];
            lsp = with pkgs; [
              cargo
              clang-tools
              lua-language-server
              rust-analyzer
              rustc
            ];
          };
          devShells = {
            llvm =
              pkgs.mkShell.override
                {
                  stdenv = pkgs.llvmPackages.libcxxStdenv;
                }
                {
                  name = "llvm";
                  packages = with pkgs; [
                    llvmPackages.bintools
                    git
                    ninja
                    cmake
                    ccache
                    (python3.withPackages (
                      ps: with ps; [
                        psutils
                        sphinx
                        myst-parser
                      ]
                    ))
                  ];
                };
          };
          legacyPackages.homeConfigurations = pkgs.lib.genAttrs [ "scott" "user" "slinder1" ] (
            user:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [ ./home/user.nix ];
              extraSpecialArgs = {
                inherit self' inputs';
                username = user;
              };
            }
          );
          formatter = pkgs.nixfmt-tree;
        };
      easy-hosts = {
        autoConstruct = true;
        path = ./hosts;
        shared.modules = [ ./modules/shared ];
        perClass = class: { modules = [ ./modules/${class} ]; };
      };
    };
}
