{
  # Bootstrap-параметры — переписываются install/phase2-system.sh.
  # Если форкаешь репо: эти значения — дефолты, под которые исходно
  # был собран репо. После установки на машине пользователя phase2
  # перезапишет файл новыми ответами.
  username  = "stefan";
  timeZone  = "Europe/Moscow";
  lanSubnet = "192.168.1.0/24";
  extras    = true;

  # Hardware profile — flake.nix читает это поле и подставляет в mkHost.
  profile   = "intel-laptop";

  # Git persona — phase2 спрашивает и тоже пишет сюда.
  fullName  = "galleb";
  email     = "s@omfm.ru";
}
