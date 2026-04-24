{ config, lib, machineType, ... }:

{
  age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

  age.secrets = lib.mkIf (machineType == "personal") {
    "aws-config" = {
      file = ../../secrets/aws-config.age;
      path = "${config.home.homeDirectory}/.aws/config";
      mode = "600";
    };
  };
}
