{ hostName, ... }:
{
  imports = [
    ../../hosts/${hostName}
    ../../modules/system
    ../../modules/drivers
  ];

  drivers.intel.enable  = true;
  drivers.laptop.enable = true;
}
