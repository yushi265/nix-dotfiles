let
  shiina = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZfBP4fCp/Bbh0XhhEXIk9hbWy1um8hdcaxEwdM7fH5 yushi265@github";
in {
  "secrets/aws-config.age".publicKeys = [ shiina ];
}
