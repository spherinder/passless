{ self }:
{ config, lib, pkgs, ... }:
let
  cfg = config.services.passless;
in {
  options.services.passless = {
    enable = lib.mkEnableOption "passless FIDO2 authenticator (UHID access + package)";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "passless.packages.\${system}.default";
      description = "The passless package to install";
    };
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "alice" ];
      description = "Users to add to the `fido` group for /dev/uhid access";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    boot.kernelModules = [ "uhid" ];
    users.groups.fido = { };
    services.udev.extraRules = ''
      KERNEL=="uhid", GROUP="fido", MODE="0660"
    '';
    users.users = lib.genAttrs cfg.users (_: {
      extraGroups = [ "fido" ];
    });
  };
}
