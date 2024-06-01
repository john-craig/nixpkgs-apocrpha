 { pkgs, lib, config, ... }: 
let
  internalProxyRules = "HeadersRegexp(`X-Real-Ip`, `(^192\.168\.[0-9]+\.[0-9]+)|(^100\.127\.79\.104)`)";
  reverseProxyNetwork = "chiliahedron-services";
  proxyTLSResolver = "chiliahedron-resolver";
  selfhostedDefinitions = import ./serviceDefinitions/default.nix;
in {
  options.services.selfhosted = {
    enable = lib.mkEnableOption "Self-hosted Services";

    services = lib.mkOption {
      type = lib.types.listOf lib.types.str;
    };
  
  };

    # services = mkOption {
    #   default = { };
    #   example = { };
    #   description = lib.mdDoc ''
    #     A definition for the selfhosted service.
    #   '';

    #   type = with types; attrsOf (submodules (
    #     { config, name, ... }: { options = {
    #       enable = mkEnableOption "Self-hosted service defined by this option";

    #       name = mkOption {
    #         visible = false;
    #         default = name;
    #         example = "nginx";
    #         type = types.str;
    #         description = lib.mdDoc "Name of the service to be run.";
    #       };
    #     }}
    #   ));
    # };

  config = lib.mkIf config.services.selfhosted.enable {
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        # Required for container networking to be able to use names.
        dns_enabled = true;
      };
    };
    virtualisation.oci-containers.backend = "podman";
    # assertions = builtins.map (service: 
    #   { lib.assertion = builtins.hasAttr service selfhostedDefinitions;
    #     message = "${service} not found in supported self-hosted service definitions"; }
    #   ) config.services.selfhosted.services;

    # The following section takes the selfhostedDefinitions object,
    # which has a format like:
    # {
    #   "serviceName1" = {
    #     ...
    #     "containers" = {
    #       "containerName1" = {
    #          ...
    #       },
    #       "containerName2" = {
    #          ...
    #       }
    #     }
    #   },
    #   "serviceName2" = {
    #     ...
    #     "containers" = {
    #       "containerName3" = {
    #          ...
    #       },
    #       "containerName4" = {
    #          ...
    #       }
    #     }
    #   }
    # }
    # and converts it into an attrset assigned to `virtualization.oci-containers.containers`
    # which looks like:
    # {
    #   "serviceName1-containerName1-container" = { ... },
    #   "serviceName1-containerName2-container" = { ... },
    #   "serviceName2-containerName3-container" = { ... },
    #   ...
    # }
    #
    virtualisation.oci-containers.containers =
      (builtins.foldl' (acc: elem: acc // elem) {} (builtins.map 
        (servName: (builtins.listToAttrs (lib.attrsets.mapAttrsToList 
          (conName: conDef: {
            name = "${servName}-${conName}";
            value = { 
              image = conDef.image;

              #######################################
              # Labels
              #######################################
              labels = {
                "wtf.chiliahedron.project-name" = servName;
              } // 
              lib.attrsets.optionalAttrs 
                (builtins.hasAttr "proxy" conDef &&
                 builtins.hasAttr "hostname" conDef.proxy &&
                 conDef.proxy.external) {
                  "traefik.enable" = "true";
                  "traefik.docker.network" = "${reverseProxyNetwork}";
                  "traefik.http.routers.${conName}-external.entryPoints" = "websecure";
                  "traefik.http.routers.${conName}-external.middlewares" = "authelia@docker";
                  "traefik.http.routers.${conName}-external.rule" = "Host(`${conDef.proxy.hostname}`)";
                  "traefik.http.routers.${conName}-external.tls" = "true";
                  "traefik.http.routers.${conName}-external.tls.certresolver" = "${proxyTLSResolver}";
                  "traefik.http.services.${conName}.loadbalancer.server.port" = (builtins.elemAt conDef.ports 0).containerPort;
                } //
              lib.attrsets.optionalAttrs 
                (builtins.hasAttr "proxy" conDef &&
                builtins.hasAttr "hostname" conDef.proxy &&
                conDef.proxy.internal) {
                  "traefik.enable" = "true";
                  "traefik.docker.network" = "${reverseProxyNetwork}";
                  "traefik.http.routers.${conName}-internal.entryPoints" = "websecure";
                  "traefik.http.routers.${conName}-internal.rule" = "Host(`${conDef.proxy.hostname}`) && ${internalProxyRules}";
                  "traefik.http.routers.${conName}-internal.tls" = "true";
                  "traefik.http.routers.${conName}-internal.tls.certresolver" = "${proxyTLSResolver}";
                  "traefik.http.services.${conName}.loadbalancer.server.port" = (builtins.elemAt conDef.ports 0).containerPort;
                } //
              lib.attrsets.optionalAttrs 
                (builtins.hasAttr "proxy" conDef &&
                builtins.hasAttr "hostname" conDef.proxy &&
                conDef.proxy.public) {
                  "traefik.enable" = "true";
                  "traefik.docker.network" = "${reverseProxyNetwork}";
                  "traefik.http.routers.${conName}-public.entryPoints" = "websecure";
                  "traefik.http.routers.${conName}-public.rule" = "Host(`${conDef.proxy.hostname}`)";
                  "traefik.http.routers.${conName}-public.tls" = "true";
                  "traefik.http.routers.${conName}-public.tls.certresolver" = "${proxyTLSResolver}";
                  "traefik.http.services.${conName}.loadbalancer.server.port" = (builtins.elemAt conDef.ports 0).containerPort;
                };

              #######################################
              # Environment Variables
              #######################################
              environment = lib.attrsets.optionalAttrs 
                (builtins.hasAttr "environment" conDef) conDef.environment;

              #######################################
              # Ports
              #######################################
              ports = lib.lists.optionals 
                (builtins.hasAttr "ports" conDef)
                (builtins.map (port: 
                  if builtins.hasAttr "protocol" port
                  then
                    "${port.hostPort}:${port.containerPort}/${port.protocol}"
                  else
                    "${port.hostPort}:${port.containerPort}/tcp"
                ) conDef.ports);
            
              #######################################
              # Volumes
              #######################################
              volumes = lib.lists.optionals 
                (builtins.hasAttr "ports" conDef)
                (builtins.map (volume: 
                  if builtins.hasAttr "mountOptions" volume
                  then
                    "${volume.hostPath}:${volume.containerPath}:${volume.mountOptions}"
                  else
                    "${volume.hostPath}:${volume.containerPath}"
                ) conDef.volumes);

              #######################################
              # Miscellaneous
              #######################################
              log-driver = "journald";

              extraOptions = 
                # Add any extra options
                lib.lists.optionals (builtins.hasAttr "extraOptions" conDef)
                  conDef.extraOptions ++

                # Connect to proxy network
                lib.lists.optional (builtins.hasAttr "proxy" conDef)
                  "--network=${reverseProxyNetwork}" ++

                # Add default network connections
                [ "--network-alias=${conName}"
                  "--network=${servName}" 
                ];

              dependsOn = lib.mkIf (builtins.hasAttr "dependsOn" conDef) conDef.dependsOn;
            };
          }) (builtins.getAttr servName selfhostedDefinitions).containers)
        )
      ) config.services.selfhosted.services));
  
    # Define users for each container within each service
    users.groups = 
      (builtins.foldl' (acc: elem: acc // elem) {} (builtins.map 
          (servName: (builtins.listToAttrs (lib.attrsets.mapAttrsToList 
            (conName: conDef: {
              name = "${servName}-${conName}-group";
              value = {};
          }) (builtins.getAttr servName selfhostedDefinitions).containers)
        )
      ) config.services.selfhosted.services));

    users.users = 
      (builtins.foldl' (acc: elem: acc // elem) {} (builtins.map 
          (servName: (builtins.listToAttrs (lib.attrsets.mapAttrsToList 
            (conName: conDef: {
              name = "${servName}-${conName}-user";
              value = { 
                isSystemUser = true;
                group = "${servName}-${conName}-group";
              };
          }) (builtins.getAttr servName selfhostedDefinitions).containers)
        )
      ) config.services.selfhosted.services));

    # Define tmpfiles for each host mount point
    systemd.tmpfiles.rules = builtins.foldl' (acc: elem: acc ++ elem) [] (builtins.map (servName:
        builtins.foldl' (acc: elem: acc ++ elem) [] (lib.attrsets.mapAttrsToList (conName: conDef: 
          builtins.map (volDef:
            let 
              hostPath = if (volDef.volumeType == "directory")
                then volDef.hostPath
                else lib.strings.concatStringsSep "/"
                  lib.lists.sublist 0 ((builtins.length (lib.strings.splitString "/" volDef.hostPath)) - 1)
                    (lib.strings.splitString "/" volDef.hostPath);
              user = "${servName}-${conName}-user";
              group = "${servName}-${conName}-group";
            in 
              "d ${volDef.hostPath} 0755 ${user} ${group}"
          )
          (lib.lists.optionals (builtins.hasAttr "volumes" conDef) conDef.volumes)
        ) (builtins.getAttr servName selfhostedDefinitions).containers)
      ) config.services.selfhosted.services);

    # Define systemd services for each container in each service,
    # and for each service
    systemd.services = 
      builtins.listToAttrs (builtins.foldl' (acc: elem: acc ++ elem) [] (builtins.map (servName:
        ((lib.attrsets.mapAttrsToList (conName: conDef: {
          name = "podman-${servName}-${conName}";
          value = { 
              serviceConfig = {
                User = "${servName}-${conName}-user";
                Restart = lib.mkOverride 500 "always";
              };
              after = [
                "podman-network-${servName}.service"
              ];
              requires = [
                "podman-network-${servName}.service"
              ];
              partOf = [
                "podman-compose-${servName}-root.target"
              ];
              wantedBy = [
                "podman-compose-${servName}-root.target"
              ];
            };
          }
        ) (builtins.getAttr servName selfhostedDefinitions).containers) ++ 
        [ {
          "name" = "podman-network-${servName}";
          "value" = {
            path = [ pkgs.podman ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStop = "${pkgs.podman}/bin/podman network rm -f ${servName}";
            };
            script = ''
              podman network inspect ${servName} || podman network create ${servName} --internal
            '';
            partOf = [ "podman-compose-${servName}-root.target" ];
            wantedBy = [ "podman-compose-${servName}-root.target" ];
          };
        } ])
       ) config.services.selfhosted.services));
    
    # Define a target for each service
    systemd.targets = 
      builtins.listToAttrs (builtins.map (servName: {
        "name" = "podman-compose-${servName}-root";
        "value" = {
          unitConfig = {
            Description = "Root target generated by compose2nix.";
          };
          wantedBy = [ "multi-user.target" ];
        };
      }) config.services.selfhosted.services);
    
  };
}