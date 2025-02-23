#!/bin/bash

dest_dir=/etc/greetd
for f in sway-config config.toml; do
    echo
    echo "==== $f ===="
    diff "$f" "$dest_dir/$f"
    sudo cp -i "$f" "$dest_dir/"
done

# If I haven't yet set a wlgreet image and I can easily find an image
# to use, then use that image.
if [ ! -r /etc/greetd/background ]; then
    if [ -d "$HOME/.desktop-images/" ]; then
	an_image=$(ls .desktop-images/ | shuf | head -1)
	if [ $? = 0 -a "X$an_image" != X ]; then
	    sudo cp -i ${an_image} /etc/greetd/background;
	fi
    fi
fi
