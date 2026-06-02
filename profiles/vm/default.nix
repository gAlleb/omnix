{ hostName, ... }:
{
  imports = [
    ../../hosts/${hostName}
    ../../modules/system
    ../../modules/drivers
  ];

  drivers.vm.enable = true;
}
