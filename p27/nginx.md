# nginx setup

Install nginx:

    sudo apt-get install -y nginx-full nginx-doc
    sudo cp nginx/nginx.conf /etc/nginx/nginx.conf
    sudo cp nginx/sites-available/* /etc/nginx/sites-available/

    (cd /etc/nginx/sites-enabled && sudo rm default)
    ###############################################################
	# Now link the appropriate local site configurations.
    ###############################################################

    sudo ufw allow http/tcp
    sudo ufw limit http
    sudo ufw allow https/tcp
    sudo ufw limit https

We want to serve https only.  The nginx site configs will promote http
to https.

    sudo apt-get install -y letsencrypt
    sudo add-apt-repository ppa:certbot/certbot
    sudo apt-get -y update
    sudo apt-get -y install python-certbot-nginx

    # Don't allow weak Diffie-Hellman keys.
    openssl dhparam -out dhparams.pem 2048 && sudo mv dhparams.pem /etc/ssl/certs/
    sudo service nginx reload

    ###############################################################
    # Now follow the local instructions for certificate generation.
    # To do that, I'll have to remove all SSL lines from the configs,
    # then re-copy them from git.
    # ##############################################################

    # And keep the certificates updated by putting this in root
    # crontab (the time is arbitrary).  Note, however, that the full
    # root crontab can just be pulled from crontab/root.
    17 5 * * *   /usr/bin/certbot renew --quiet

