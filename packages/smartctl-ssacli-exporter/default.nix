{ lib, pkgs, buildGoModule, fetchFromGitHub }: 

buildGoModule rec { 
  name = "smartctl-ssacli-exporter";

  src = fetchFromGitHub {
    owner = "john-craig";
    repo = "smartctl_ssacli_exporter";
    rev = "2ac1fd36634d855c1479cf6f068d0de8cc64d30c";
    hash = "sha256-8YYI5atnEuZONiSFc/7FlPCIlKkbDQMj7hPpUWpeon4=";
  };

  vendorHash = "sha256-m+V6A2DWcyIcCII5om1WYr7QmuiTY3pSmpEKaheg/Oc=";

  meta = with lib; {
    description = "Export metric from HP enterprise raid card & disk smartctl with auto detect disk";
    mainProgram = "smartctl_ssacli_exporter";
    homepage = "https://github.com/john-craig/smartctl_ssacli_exporter";
    #license = licenses.apache;
  };
}