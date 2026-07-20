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
    cm = {
      url = "github:ROCm/cm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cgh = {
      url = "github:slinder1/cgh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      easy-hosts,
      home-manager,
      cm,
      cgh,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        easy-hosts.flakeModule
        home-manager.flakeModules.home-manager
      ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      flake.homeModules = {
        core =
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
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
              hyperfine
              ov
              ripgrep
              starship
              uv
              xxd
            ];
          };
        core-src =
          { pkgs, system, ... }:
          {
            home.packages = with pkgs; [
              cm.packages.${system}.cm
              cgh.packages.${system}.cgh
            ];
          };
        lsp =
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              cargo
              clang-tools
              lua-language-server
              rust-analyzer
              rustc
              rustfmt
            ];
          };
      };
      perSystem =
        {
          self',
          inputs',
          system,
          lib,
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
          legacyPackages.homeConfigurations = pkgs.lib.genAttrs [ "scott" "user" "slinder1" ] (
            user:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit self' inputs' system;
                homeModules = self.homeModules;
              };
              modules = (lib.optional (builtins.pathExists ~/.config/home.nix) ~/.config/home.nix) ++ [
                {
                  home.username = user;
                  home.homeDirectory = ~/.;
                  home.stateVersion = "25.11";
                }
              ];
            }
          );
          devShells = {
            llvm =
              let
                venvPath = ".venv";
              in
              pkgs.mkShell {
                name = "llvm";
                packages = with pkgs; [
                  ccache
                  cmake
                  git
                  graphviz
                  llvmPackages.bintools
                  ninja
                  uv
                  (python3.withPackages (
                    ps: with ps; [
                      psutils
                    ]
                  ))
                  (pkgs.writeShellApplication {
                    name = "llvmdev-update-python";
                    text = ''
                      set -x
                      uv pip install --upgrade -r llvm/docs/requirements.txt
                      uv pip install --upgrade swig
                      uv pip install --upgrade black=='23.*' darker
                      uv pip install --upgrade pyright types-docutils
                    '';
                  })
                ];
                shellHook = ''
                  if [ ! -d ${venvPath} ]; then
                    printf "[shell_hook] Creating ${venvPath}\n"
                    uv venv ${venvPath}
                  fi
                  printf "[shell_hook] Activating ${venvPath}\n"
                  source ${venvPath}/bin/activate
                  printf "[shell_hook] Helper commands available:\n"
                  compgen -c llvmdev- | sed 's/^/\t/'
                '';
              };
            rock1030 =
              let
                #family = "gfx103X-all";
                #venvPath = ".venv.gfx103X-all";
                family = "";
                venvPath = ".venv";
                libraryPath = pkgs.lib.makeLibraryPath [
                  pkgs.stdenv.cc.cc.lib
                  pkgs.libdrm
                ];
              in
              pkgs.mkShellNoCC {
                name = "rock";
                packages = with pkgs; [
                  autoconf
                  automake
                  bison
                  ccache
                  #cmake
                  dvc
                  flex
                  gfortran # also includes g++, etc.
                  glibc
                  git
                  libdrm
                  libtool
                  libGL
                  ncurses # just for libtinfo, since therock builds its own ncurses
                  ninja
                  pkg-config
                  python3
                  texinfo
                  uv
                  (stdenv.mkDerivation rec {
                    pname = "patchelf-rocm";
                    version = "d0f70eea5397606c486857e0a105e53ec123904a";

                    src = fetchGit {
                      url = "https://github.com/NixOS/${pname}";
                      rev = "${version}";
                    };

                    patchPhase = ''
                      PATCHELF_GIT_REF="${version}"
                      SHORT_GIT_REF="''${PATCHELF_GIT_REF:0:12}"
                      BASE_VERSION="$(cat version)"
                      LOCAL_VERSION="''${BASE_VERSION}+therock.''${SHORT_GIT_REF}"
                      printf "%s\n" "''${LOCAL_VERSION}" > version
                    '';

                    nativeBuildInputs = [ autoreconfHook ];
                  })
                  (pkgs.writeShellApplication {
                    name = "therock-update-python";
                    text = ''
                      set -x
                      uv pip install --upgrade -r requirements.txt
                      uv pip install cmake==3.28.3
                      #uv pip install --upgrade 'rocm[libraries,devel]' --index-url=https://rocm.nightlies.amd.com/v2/${family}
                    '';
                  })
                  (pkgs.writeShellApplication {
                    name = "therock-fetch-sources";
                    text = ''
                      set -x
                      python3 ./build_tools/fetch_sources.py
                    '';
                  })
                ];
                NIX_CFLAGS_COMPILE = "-I${pkgs.libdrm.dev}/include";
                LD_LIBRARY_PATH = libraryPath;
                CMAKE_PREFIX_PATH = libraryPath;
                HSA_OVERRIDE_GFX_VERSION = "10.3.0";
                CM_CONF_EXTRA = ''
                  -DTHEROCK_AMDGPU_FAMILIES=gfx103X-all
                  -DTHEROCK_USE_LLD=ON
                  -DFLANG_PARALLEL_COMPILE_JOBS=16
                  -DLLVM_PARALLEL_LINK_JOBS=16
                '';
                shellHook = ''
                  if [ ! -d ${venvPath} ]; then
                    printf "[shell_hook] Creating ${venvPath}\n"
                    python3 ./build_tools/setup_venv.py ${venvPath} --use-uv #\
                      #--packages 'rocm[libraries,devel]' --index-name nightly --index-subdir ${family}
                  fi
                  printf "[shell_hook] Activating ${venvPath}\n"
                  source ${venvPath}/bin/activate
                  if [ ! -d .ccache ]; then
                    printf "[shell_hook] Creating .ccache\n"
                    eval "$(python3 ./build_tools/setup_ccache.py)"
                  else
                    printf "[shell_hook] Activating .ccache\n"
                    export CCACHE_CONFIGPATH="$PWD"/.ccache/ccache.conf
                  fi
                  printf "[shell_hook] Helper commands available:\n"
                  compgen -c therock- | sed 's/^/\t/'
                '';
              };
            rust = pkgs.mkShell {
              packages = with pkgs; [
                rustc
                cargo
                rust-analyzer
              ];
              nativeBuildInputs = with pkgs; [
                pkg-config
              ];
              buildInputs = with pkgs; [
                openssl
              ];
            };
          };
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
