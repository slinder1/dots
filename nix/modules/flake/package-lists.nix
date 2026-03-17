{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
in
{
  options = {
    flake.package-lists = mkOption {
      type = types.lazyAttrsOf types.unspecified;
      default = { };
      description = ''
        TODO
      '';
    };

    perSystem = mkPerSystemOption {
      _file = ./package-lists.nix;
      options = {
        package-lists = mkOption {
          type = types.lazyAttrsOf types.unspecified;
          default = { };
          description = ''
            TODO
          '';
        };
      };
    };
  };
  config = {
    flake.package-lists = mapAttrs (k: v: v.package-lists) (
      filterAttrs (k: v: v.package-lists != null) config.allSystems
    );

    perInput =
      system: flake:
      optionalAttrs (flake ? package-lists.${system}) {
        package-lists = flake.package-lists.${system};
      };

  };
}
