{
  description = "Apocryphal Utilities";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }@inputs: {
    utilities = rec {
      mkNotifierScript = title: message: tokenPath:
        ''
          GOTIFY_TOKEN=$(cat ${tokenPath})
          DISPLAY_DATE=$(date)
          curl -s -S --data '{"message": "'"${message}"'", "title": "'"${title}"'", "priority":'"1"', "extras": {"client::display": {"contentType": "text/markdown"}}}' -H 'Content-Type: application/json' "https://gotify.chiliahedron.wtf/message?token=$GOTIFY_TOKEN"
        '';
      
      mkNotifiedService = serviceName: serviceDef: tokenPath: (
        {
          "${serviceName}" = (
            serviceDef // {
              onSuccess = [ "${serviceName}-success-notifier.service" ];
              onFailure = [ "${serviceName}-failure-notifier.service" ];
            }
          );
          "${serviceName}-success-notifier" = {
            enable = true;
            path = [ nixpkgs.pkgs.curl ];
            script = mkNotifierScript ("${serviceName} Succeeded"
              "${serviceName} succeeded on $DISPLAY_DATE"
              tokenPath);
            serviceConfig = {
              Type = "oneshot";
              User = "root";
            };
          };
          "${serviceName}-failure-notifier" = {
            enable = true;
            path = [ nixpkgs.pkgs.curl ];
            script = mkNotifierScript  ("${serviceName} Failed"
              "${serviceName} failed on $DISPLAY_DATE"
              tokenPath);
            serviceConfig = {
              Type = "oneshot";
              User = "root";
            };
          };
        }
      );

    };
  };
    
}
