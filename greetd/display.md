The greeter is wlgreet running under sway, started by greetd.  Both
come from the Ubuntu packages (`greetd` and `wlgreet` in 2604-LTS.pkg).

2604-LTS.sh runs greetd/install.sh, which can also be re-run by hand
after editing the config here.  It installs:

  greetd/config.toml           -> /etc/greetd/local/config.toml
  greetd/sway-config           -> /etc/greetd/local/sway-config
  greetd/greetd-override.conf  -> /etc/systemd/system/greetd.service.d/local-config.conf

The drop-in starts greetd with `--config /etc/greetd/local/config.toml`.
Nothing we edit is a package conffile, so package upgrades never stop to
ask about /etc/greetd/config.toml (greetd) or /etc/greetd/sway-config
(wlgreet).  Those stay as shipped and unused; install.sh puts them back
if an earlier version edited them, keeping the edited copy as `.bak`.

It also makes greetd the display manager (`systemctl enable
greetd.service --force`, which points
/etc/systemd/system/display-manager.service at greetd.service) and
removes gdm3.

Up to 24.04 I built wlgreet from source, because I needed at least
0.5 and Ubuntu shipped 0.4.1.  26.04 ships 0.5.0, which is also the
latest upstream release (https://git.sr.ht/~kennylevinsen/wlgreet, as
of 2026-11).  install.sh removes a leftover /usr/local/bin/wlgreet.
The packaged binary is /usr/sbin/wlgreet.
