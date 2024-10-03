To make the system boot to using greetd, I must change the symlink:

  /etc/systemd/system/display-manager.service
  ->
  /lib/systemd/system/greetd.service
