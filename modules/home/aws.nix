{ lib, machineType, ... }:

{
  programs.awscli = lib.mkIf (machineType == "personal") {
    enable = true;
    settings = {
      "default" = {
        region = "ap-northeast-1";
        output = "json";
      };
      "profile yushi265" = {
        region = "ap-northeast-1";
        output = "json";
      };
      "profile AdministratorAccess-288632681694" = {
        sso_session = "coleta";
        sso_account_id = "288632681694";
        sso_role_name = "AdministratorAccess";
        region = "ap-northeast-1";
        output = "json";
      };
      "sso-session coleta" = {
        sso_start_url = "https://d-9567623602.awsapps.com/start";
        sso_region = "ap-northeast-1";
        sso_registration_scopes = "sso:account:access";
      };
      "profile coleta/tf" = {
        sso_account_id = "288632681694";
        sso_role_name = "PowerUserAccess";
        sso_start_url = "https://d-9567623602.awsapps.com/start";
        sso_region = "ap-northeast-1";
        sso_session = "coleta";
        region = "ap-northeast-1";
      };
      "profile coleta-dev/tf" = {
        sso_account_id = "550299169809";
        sso_role_name = "PowerUserAccess";
        sso_start_url = "https://d-9567623602.awsapps.com/start";
        sso_region = "ap-northeast-1";
        sso_session = "coleta";
        region = "ap-northeast-1";
      };
      "profile AdministratorAccess-550299169809" = {
        sso_session = "coleta";
        sso_account_id = "550299169809";
        sso_role_name = "AdministratorAccess";
        region = "ap-northeast-1";
        output = "json";
      };
      "profile ReadOnlyAccess-550299169809" = {
        sso_session = "coleta";
        sso_account_id = "550299169809";
        sso_role_name = "ReadOnlyAccess";
        region = "ap-northeast-1";
        output = "json";
      };
      "profile PowerUserAccess-550299169809" = {
        sso_session = "coleta";
        sso_account_id = "550299169809";
        sso_role_name = "PowerUserAccess";
        region = "ap-northeast-1";
        output = "json";
      };
    };
  };
}
