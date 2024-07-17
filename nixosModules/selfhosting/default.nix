 { services-library, ... }: 
 { pkgs, lib, config, ... }: 
let
  internalProxyRules = "HeadersRegexp(`X-Real-Ip`, `(^192\.168\.[0-9]+\.[0-9]+)|(^100\.127\.79\.104)`)";
  reverseProxyNetwork = "chiliahedron-services";
  proxyTLSResolver = "chiliahedron-resolver";
  
  shLib = import ./lib/default.nix;
  servicesLibrary = services-library.default;
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

  config = let
    serviceDefinitions = lib.attrsets.getAttrs
        config.services.selfhosted.services
        servicesLibrary;

      # Invoke the function 'func' with
      #   acc: servName: servDef
      # for each service in services
      reduceServices = func: init: services: (
        lib.attrsets.foldlAttrs func init services
      );

      # Invoke the function 'func' with
      #   acc: servName: servDef: conName: conDef
      # for each container in each service
      reduceContainers = func: init: services: (
        reduceServices (
          # Lambda function passed to 'reduceServices'
          acc: servName: servDef: (
            # Reduce attribute set of the containers
            # inside this services definition
            lib.attrsets.foldlAttrs (
              # Lambda definition called when reducing
              # each container definition
              acc: conName: conDef: (
                # Actual invocation of caller's lambda function
                func acc servName servDef conName conDef
              )
            ) acc servDef.containers
          )) init services
        );

    in lib.mkIf config.services.selfhosted.enable {
    environment.systemPackages = [
      pkgs.acl
      pkgs.gnugrep
    ];

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

    virtualisation.oci-containers.containers =
      (reduceContainers (acc: servName: servDef: conName: conDef: (
        acc // {
          "${servName}-${conName}" = {
            image = conDef.image;
            
            user = "${servName}-${conName}:${servName}-${conName}";

            cmd = lib.lists.optionals
              (builtins.hasAttr "cmd" conDef) conDef.cmd;

            #######################################
            # Labels
            #######################################
            labels = {
              "wtf.chiliahedron.project-name" = servName;
            } // 
            lib.attrsets.optionalAttrs 
              (builtins.hasAttr "proxy" conDef &&
                builtins.hasAttr "hostname" conDef.proxy &&
                builtins.hasAttr "external" conDef.proxy &&
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
              builtins.hasAttr "internal" conDef.proxy &&
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
              builtins.hasAttr "public" conDef.proxy &&
              conDef.proxy.public) {
                "traefik.enable" = "true";
                "traefik.docker.network" = "${reverseProxyNetwork}";
                "traefik.http.routers.${conName}-public.entryPoints" = "websecure";
                "traefik.http.routers.${conName}-public.rule" = "Host(`${conDef.proxy.hostname}`)";
                "traefik.http.routers.${conName}-public.tls" = "true";
                "traefik.http.routers.${conName}-public.tls.certresolver" = "${proxyTLSResolver}";
                "traefik.http.services.${conName}.loadbalancer.server.port" = (builtins.elemAt conDef.ports 0).containerPort;
              } //
            lib.attrsets.optionalAttrs
              (builtins.hasAttr "extraLabels" conDef) conDef;

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
            volumes = [ 
              "/etc/passwd:/etc/passwd:ro" 
              "/etc/group:/etc/group:ro"
            ] ++ lib.lists.optionals 
              (builtins.hasAttr "volumes" conDef)
              (builtins.map (volDef: 
                let
                  conPath = volDef.containerPath;
                  hostPath = volDef.hostPath;

                  conBase = builtins.baseNameOf conPath;
                  varHash = builtins.hashString "sha256" "${hostPath}-${conPath}";

                  varPath = "/var/lib/selfhosted/${servName}/${conName}/${varHash}-${conBase}";
                in
                  if builtins.hasAttr "mountOptions" volDef
                  then
                    "${varPath}:${volDef.containerPath}:${volDef.mountOptions}"
                  else
                    "${varPath}:${volDef.containerPath}"
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
              lib.lists.optionals (builtins.hasAttr "proxy" conDef)
                [ "--network=${reverseProxyNetwork}" ] ++

              # Connect to external network
              lib.lists.optionals (builtins.hasAttr "networks" conDef &&
                builtins.hasAttr "external" conDef.networks &&
                conDef.networks.external)
                [ "--network=${servName}-external" ] ++

              # Add default network connections
              [ "--network-alias=${conName}"
                "--network=${servName}-internal" 
              ];

            dependsOn = lib.mkIf (builtins.hasAttr "dependsOn" conDef) conDef.dependsOn;
          };
        })
      ) {} serviceDefinitions);



      # (builtins.foldl' (acc: elem: acc // elem) {} (builtins.map 
      #   (servName: (builtins.listToAttrs (lib.attrsets.mapAttrsToList 
      #     (conName: conDef: {
      #       name = "${servName}-${conName}";
      #       value = { 
              
      #     }) (builtins.getAttr servName servicesLibrary).containers)
      #   )
      # ) config.services.selfhosted.services));
  
    # Define users for each container within each service
    users.groups = (reduceContainers (acc: servName: servDef: conName: conDef: (
        acc // {
          "${servName}-${conName}" = {};
        })
      )) {} serviceDefinitions;

    users.users = (reduceContainers (acc: servName: servDef: conName: conDef: (
        acc // {
          "${servName}-${conName}" = { 
            isSystemUser = true;
            group = "${servName}-${conName}";
          };
        })
      )) {} serviceDefinitions;

    # Define tmpfiles for each container
    systemd.tmpfiles.rules = (reduceContainers (acc: servName: servDef: conName: conDef: (
      acc ++ [
        (let 
          user = "${servName}-${conName}"; 
          group = "${servName}-${conName}";
        in 
          "d /var/lib/selfhosted/${servName}/${conName} 0700 ${user} ${group}")
      ])
    )) [] serviceDefinitions;

    systemd.services = 
      # Define services to set up the mountpoints for each container
      ((reduceContainers (acc: servName: servDef: conName: conDef: (
        acc // {
          "podman-mount-${servName}-${conName}" = {
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            # Setup
            script = lib.strings.concatMapStrings (volDef:
              let
                user = "${servName}-${conName}";
                group = "${servName}-${conName}";

                # Translate "rw,Z" or "ro", etc. to "rw" or "r" for setfacl
                volPerms = if 
                  ((builtins.elemAt (lib.strings.splitString "," volDef.mountOptions) 0) == "ro")
                  then "r"
                  else "rwx";

                conPath = volDef.containerPath;
                hostPath = volDef.hostPath;

                conBase = builtins.baseNameOf conPath;
                varHash = builtins.hashString "sha256" "${hostPath}-${conPath}";

                varPath = "/var/lib/selfhosted/${servName}/${conName}/${varHash}-${conBase}";
              in ''
                # Check to see if the file on the hostpath already allows the correct permissions
                # The output of `getfacl -ac` looks like this:
                #     user::rwx
                #     user:timeflip-tracker-database:rw-
                #     group::---
                #     group:timeflip-tracker-database:rw-
                #     mask::rw-
                #     other::---
                # So we can use a regular expression with grep to see if either our user/group has permission, or
                # the 'other' category has permission. Note that this doesn't cover the actual base user/group of
                # the directory.
                $(${pkgs.acl}/bin/getfacl -ac ${hostPath} | ${pkgs.gnugrep}/bin/grep -E '(:${user}:|:${group}:|other::)' | ${pkgs.gnugrep}/bin/grep -E -q ':${volPerms}') || $(${pkgs.acl}/bin/setfacl -R -m u:${user}:${volPerms} ${hostPath}; ${pkgs.acl}/bin/setfacl -R -m g:${group}:${volPerms} ${hostPath};)

                # Create a symlink to that volume path
                stat ${varPath} || $(ln -s ${hostPath} ${varPath} && chown -Rh ${user}:${group} ${varPath})
              '') conDef.volumes;
            
            # Cleanup
            postStop = lib.strings.concatMapStrings (volDef:
              let
                user = "${servName}-${conName}";
                group = "${servName}-${conName}";

                conPath = volDef.containerPath;
                hostPath = volDef.hostPath;

                conBase = builtins.baseNameOf conPath;
                varHash = builtins.hashString "sha256" "${hostPath}-${conPath}";

                varPath = "/var/lib/selfhosted/${servName}/${conName}/${varHash}-${conBase}";
              in ''
                # Remove extended attributes
                ${pkgs.acl}/bin/setfacl -R -x u:${user} ${hostPath}
                ${pkgs.acl}/bin/setfacl -R -x g:${group} ${hostPath}

                rm -f ${varPath}
              '') conDef.volumes;
            after = [
              # Put user-defined "preMountHooks" here
            ];
            requires = [
              # Put user-defined "preMountHooks" here
              # TODO: make this dependant upon the tmpfiles
            ];
            partOf = [
              "podman-compose-${servName}-root.target"
            ];
            wantedBy = [
              "podman-compose-${servName}-root.target"
            ];
          };
        })
      )) {} serviceDefinitions) //
      # Define services for each container
      ((reduceContainers (acc: servName: servDef: conName: conDef: (
        acc // {
          "podman-${servName}-${conName}" = {
            serviceConfig = {
              Restart = lib.mkOverride 500 "always";
            };
            after = [
              "podman-network-${servName}.service"
              "podman-mount-${servName}-${conName}.service"
            ];
            requires = [
              "podman-network-${servName}.service"
              "podman-mount-${servName}-${conName}.service"
            ];
            partOf = [
              "podman-compose-${servName}-root.target"
            ];
            wantedBy = [
              "podman-compose-${servName}-root.target"
            ];
          };
        })
      )) {} serviceDefinitions) //
      # Define networks for each service
      (reduceServices (acc: servName: servDef: (
        acc // {
          "podman-network-${servName}" = {
            path = [ pkgs.podman ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              podman network inspect ${servName}-internal || podman network create ${servName}-internal --internal
              podman network inspect ${servName}-external || podman network create ${servName}-external
            '';
            postStop = ''
              ${pkgs.podman}/bin/podman network rm -f ${servName}-internal
              ${pkgs.podman}/bin/podman network rm -f ${servName}-external
            '';
            partOf = [ "podman-compose-${servName}-root.target" ];
            wantedBy = [ "podman-compose-${servName}-root.target" ];
          };
        })
      ) {} serviceDefinitions);
    
    # Define a target for each service
    systemd.targets = 
      builtins.listToAttrs (builtins.map (servName: {
        "name" = "podman-compose-${servName}-root";
        "value" = {
          unitConfig = {
            Description = "Root target for ${servName} service";
          };
          wantedBy = [ "multi-user.target" ];
        };
      }) config.services.selfhosted.services);
  };
}