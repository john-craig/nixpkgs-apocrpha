{ pkgs, lib, config, utils, ... }:

with utils;

let
  mkGotifyNotifierScript = title: message: tokenPath: gotifyUrl:
    ''
      GOTIFY_TOKEN=$(cat ${tokenPath})
      DISPLAY_DATE=$(date)
      curl -s -S --data '{"message": "'"${message}"'", "title": "'"${title}"'", "priority":'"1"', "extras": {"client::display": {"contentType": "text/markdown"}}}' -H 'Content-Type: application/json' "${gotifyUrl}/message?token=$GOTIFY_TOKEN"
    '';

  mkNotifiedService = serviceName: serviceDef: mkNotifierScript: (
    {
      "${serviceName}" = (
        serviceDef // {
          onSuccess = [ "${serviceName}-success-notifier.service" ];
          onFailure = [ "${serviceName}-failure-notifier.service" ];
        }
      );
      "${serviceName}-success-notifier" = {
        enable = true;
        path = [ pkgs.curl ];
        script = (mkNotifierScript
          "${serviceName} Succeeded"
          "${serviceName} succeeded on $DISPLAY_DATE");
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
      "${serviceName}-failure-notifier" = {
        enable = true;
        path = [ pkgs.curl ];
        script = (mkNotifierScript
          "${serviceName} Failed"
          "${serviceName} failed on $DISPLAY_DATE");
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    });
in
{
  options.notifiedServices = {
    enable = lib.mkEnableOption "Notified Services";

    method = lib.mkOption {
      description = "Notification method";

      type = lib.types.submodule {
        options = {
          # Only supported option
          gotify = lib.mkOption {
            description = "Notifications using Gotify";

            type = lib.types.submodule {
              options = {
                tokenPath = lib.mkOption {
                  description = "Path to Gotify token";
                  type = lib.types.str;
                };

                url = lib.mkOption {
                  description = "Gotify Server URL";
                  type = lib.types.str;
                };
              };
            };
          };
        };
      };
    };

    services = lib.mkOption {
      default = { };
      type = lib.types.attrs;
      # type = systemdUtils.types.services;
      description = "Definition of systemd service units; see {manpage}`systemd.service(5)`.";
    };
  };

  config = lib.mkIf config.notifiedServices.enable {
    assertions = [
      {
        assertion = (builtins.hasAttr "gotify" config.notifiedServices.method);
        message = "Must specify a notification method";
      }
    ];

    environment.systemPackages = lib.mkIf (builtins.hasAttr "gotify" config.notifiedServices.method) [
      pkgs.curl
    ];

    systemd.services =
      let
        mkNotifierScript = (title: message:
          (mkGotifyNotifierScript title message
            config.notifiedServices.method.gotify.tokenPath
            config.notifiedServices.method.gotify.url));
      in
      lib.attrsets.foldlAttrs
        (acc: servName: servDef:
          acc // (mkNotifiedService servName servDef mkNotifierScript))
        { }
        config.notifiedServices.services;
  };
}
