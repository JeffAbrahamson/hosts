I'll need atleast wlgreet 1.5.  Until that is available in the ubuntu
repos, I compile from source.

    git clone https://github.com/kennylevinsen/greetd.git
    git clone https://git.sr.ht/~kennylevinsen/wlgreet

Each has a README.md with instructions on how to compile and install.

I'm pretty sure I only need to compile wlgreet from source, that the
default greetd is fine.

To make the system boot to using greetd, I must change this symlink:

  /etc/systemd/system/display-manager.service
  ->
  /etc/systemd/system/greetd.service
