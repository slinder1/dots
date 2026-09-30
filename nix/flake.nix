{
  description = "scott's dots";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    easy-hosts.url = "github:tgirlcloud/easy-hosts";
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    praddle = {
      url = "github:slinder1/praddle";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      easy-hosts,
      neovim-nightly-overlay,
      home-manager,
      cm,
      praddle,
      ...
    }:
    let
      uvWrapped =
        pkgs:
        pkgs.buildFHSEnv {
          name = "uv";
          runScript = "${pkgs.uv}/bin/uv";
          targetPkgs =
            pkgs: with pkgs; [
              stdenv.cc.cc
              zlib
              glibc
              libgcc
              glib
            ];
        };
    in
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
              ccache
              coreutils
              delta
              fd
              fzf
              gh
              git
              hyperfine
              neovim
              ov
              ripgrep
              starship
              tree-sitter
              xxd
              (uvWrapped pkgs)
            ];
          };
        core-src =
          { pkgs, system, ... }:
          {
            home.packages = with pkgs; [
              cm.packages.${system}.default
              praddle.packages.${system}.default
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
        nvimd =
          { pkgs, ... }:
          {
            systemd.user.services.nvimd = {
              Unit.Description = "nvim daemon";
              Install.WantedBy = [ "default.target" ];
              Service = {
                RuntimeDirectory = "nvimd";
                ExecStartPre = "/bin/rm -f \${RUNTIME_DIRECTORY}/sock";
                ExecStart = "/bin/bash -l -c '. %h/.bash_aliases && exec ${pkgs.neovim}/bin/nvim --listen \${RUNTIME_DIRECTORY}/sock --headless -c \"let &titlestring = hostname() | set title\"'";
                Restart = "always";
              };
            };
          };
        llvm-build =
          { pkgs, system, ... }:
          {
            systemd.user.services."llvm-build@" = {
              Unit.Description = "build llvm in %h/llvm-project/%i";
              Service = {
                Type = "oneshot";
                WorkingDirectory = "%h/llvm-project/%i";
                StandardOutput = "journal";
                StandardError = "journal";
                ExecStart = "${pkgs.nix}/bin/nix develop --impure path:${self.outPath}#llvm --command ${pkgs.writeShellScript "llvm-build" ''
                  rm -rf build || exit 1
                  git fetch https://github.com/llvm/llvm-project.git main || exit 1
                  git switch --detach FETCH_HEAD || exit 1
                  cm c || exit 1
                  cm b || exit 1
                  cm l -ga || exit 1
                ''}";
              };
            };
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
          legacyPackages.homeConfigurations = pkgs.lib.genAttrs [ "user" "scott" "slinder1" ] (
            user:
            home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              extraSpecialArgs = {
                inherit
                  self'
                  inputs'
                  system
                  user
                  ;
                homeModules = self.homeModules;
              };
              modules = [
                {
                  nixpkgs.overlays = [ neovim-nightly-overlay.overlays.default ];
                }
                ./home.nix
              ];
            }
          );
          devShells = {
            llvm =
              let
                venvPath = ".venv";
                gccForLibs = pkgs.stdenv.cc.cc;
              in
              pkgs.mkShell.override { stdenv = pkgs.clangStdenv; } {
                name = "llvm";
                packages = with pkgs; [
                  ccache
                  cmake
                  git
                  graphviz
                  llvmPackages.bintools
                  ninja
                  (uvWrapped pkgs)
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
                  export CC=clang
                  export CXX=clang++
                  export NIX_LDFLAGS="-L${gccForLibs}/lib/gcc/${pkgs.stdenv.targetPlatform.config}/${gccForLibs.version} $NIX_LDFLAGS"
                  export CFLAGS="-B${gccForLibs}/lib/gcc/${pkgs.stdenv.targetPlatform.config}/${gccForLibs.version} -B ${pkgs.stdenv.cc.libc}/lib $CFLAGS"
                  export CXXFLAGS="-B${gccForLibs}/lib/gcc/${pkgs.stdenv.targetPlatform.config}/${gccForLibs.version} -B ${pkgs.stdenv.cc.libc}/lib $CXXFLAGS"
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
                  (uvWrapped pkgs)
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
