{ hostName, ... }:
{
  imports = [
    ../../hosts/${hostName}
    ../../modules/system
    ../../modules/drivers
  ];

  drivers.amd.enable = true;
}
