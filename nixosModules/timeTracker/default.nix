{ pkgs, lib, config, ... }: {
  options.timeTracker = {
    enable = lib.mkEnableOption "Time Tracker";

  };

  config = lib.mkIf config.timeTracker.enable {
    environment.systemPackages = with pkgs; [
      timeflip-tracker
    ];

    environment.etc."timeflip-tracker/config.yaml".text =
      let
        onFacetChange = pkgs.writeScriptBin "onFacetChange" ''
          DEVICE=$1
          MAC_ADDR=$2
          FACET_NUM=$3
          FACET_VAL=$4

          # Colors are separated like (rr, gg, bb)
          FACET_COLOR_RED=$(echo $5 | cut -d' ' -f 1 | tr -d '(,')
          FACET_COLOR_GREEN=$(echo $5 | cut -d' ' -f 2 |  tr -d ',')
          FACET_COLOR_BLUE=$(echo $5 | cut -d' ' -f 3 |  tr -d ',)')

          API_TOKEN_PATH=/run/secrets/nocodb/service/api_token
          { echo -n 'xc-token: '; cat $API_TOKEN_PATH | tr -d '\n'; } | \
          ${pkgs.curl}/bin/curl -X 'POST' \
            'https://nocodb.chiliahedron.wtf/api/v2/tables/mvrlvujs9d2kwyi/records' \
            -H 'accept: application/json' \
            -H @- \
            -H 'Content-Type: application/json' \
            -d "{ \"Device Name\": \"$DEVICE\", \"MAC Address\": \"$MAC_ADDR\", \"Facet Number\": $FACET_NUM, \"Facet Value\": \"$FACET_VAL\", \"Facet Color Red\": $FACET_COLOR_RED, \"Facet Color Green\": $FACET_COLOR_GREEN, \"Facet Color Blue\": $FACET_COLOR_BLUE }"
        '';
      in
      ''
        adapter: "B8:9A:2A:3F:0E:B6"
        devices:
        - name: timeflip1
          mac_address: "D0:A1:FC:9C:B2:46"
          password: '0000'
          default_color: "disco"
          actions: # Optional, invoked in addition to database
              on_facet_change: "${onFacetChange}/bin/onFacetChange \"$@\""
              on_connect: "echo \"$@\" > /tmp/on_connect.txt"
              on_disconnect: "echo \"$@\" > /tmp/on_disconnect.txt"
          facets:
          - value: "studying" #1
          - value: "chores" #2
          - value: "writing" #3
          - value: "development" #4
          - value: "reading" #5
          - value: "streaming" #6
          - value: "exercise" #7
          - value: "administrivia" #8
          - value: "television" #9
          - value: "break" #10
          - value: "music" #11
          - value: "meeting"  #12
      '';

    systemd.services."track-time" = {
      enable = true;
      script = ''
        ${pkgs.timeflip-tracker}/bin/timeflip-tracker
      '';
      serviceConfig = {
        Type = "simple";
        User = "service";
      };

      after = [ "bluetooth.service" ]; # Run after the Bluetooth service starts
      bindsTo = [ "bluetooth.service" ]; # Ensure Bluetooth is started before this service
      wantedBy = [ "bluetooth.service" ]; # Ensure Bluetooth is started before this service
    };

  };
}
