{ ... }:
{
  imports = [
    ./intel.nix
    ./amd.nix
    ./nvidia.nix
    ./nvidia-prime.nix
    ./laptop.nix
    ./vm.nix
  ];
}
