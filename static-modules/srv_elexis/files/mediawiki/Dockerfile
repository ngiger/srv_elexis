from debian:jessie

env DEBIAN_FRONTEND noninteractive
env MEDIAWIKI_VERSION_MAJOR 1.22
env MEDIAWIKI_VERSION_MINOR 6
run apt-get update
run apt-get install -y php5-mcrypt php5-sqlite php5-mysql sqlite php5-gd php5-intl imagemagick pwgen mysql-client wget

run wget -O - http://releases.wikimedia.org/mediawiki/${MEDIAWIKI_VERSION_MAJOR}/mediawiki-${MEDIAWIKI_VERSION_MAJOR}.${MEDIAWIKI_VERSION_MINOR}.tar.gz | tar xzf - -C /srv
#add mediawiki-${MEDIAWIKI_VERSION_MAJOR}.${MEDIAWIKI_VERSION_MINOR}.tar.gz /srv/
run mv /srv/mediawiki-${MEDIAWIKI_VERSION_MAJOR}.${MEDIAWIKI_VERSION_MINOR} /srv/mediawiki
run chown -R www-data /srv/mediawiki/mw-config
run ln -sf /srv/mediawiki/config/LocalSettings.php /srv/mediawiki/LocalSettings.php

add site.conf /etc/nginx/sites-enabled/default

add entrypoint.sh /entrypoint.sh
run apt-get install -y supervisor nginx-light php5-fpm php5-cli
run echo 'cgi.fix_pathinfo=0' >>/etc/php5/fpm/php.ini
add supervisor.conf /etc/supervisor/conf.d/nginx.conf
ADD ./fpm.conf /etc/php5/fpm/php-fpm.conf
ADD ./fpm-pool-www.conf /etc/php5/fpm/pool.d/www.conf

volume /srv/mediawiki/images
volume /srv/mediawiki/config
volume /srv/www

RUN apt-get install -y curl
ADD assets/add_extension.sh /usr/local/bin/add_extension.sh
RUN /usr/local/bin/add_extension.sh BlockandNuke      https://extdist.wmflabs.org/dist/extensions/BlockAndNuke-REL1_25-f01f9b7.tar.gz
RUN /usr/local/bin/add_extension.sh Collection        https://extdist.wmflabs.org/dist/extensions/Collection-REL1_25-d898236.tar.gz
RUN /usr/local/bin/add_extension.sh ConfirmEdit       https://extdist.wmflabs.org/dist/extensions/ConfirmEdit-REL1_25-48cc81c.tar.gz
RUN /usr/local/bin/add_extension.sh LanguageSelector  https://extdist.wmflabs.org/dist/extensions/LanguageSelector-REL1_25-d230e55.tar.gz
RUN /usr/local/bin/add_extension.sh Nuke              https://extdist.wmflabs.org/dist/extensions/Nuke-REL1_25-e18b127.tar.gz
RUN /usr/local/bin/add_extension.sh Vector            https://extdist.wmflabs.org/dist/extensions/Vector-REL1_25-8c5d979.tar.gz
RUN /usr/local/bin/add_extension.sh WikiEditor        https://extdist.wmflabs.org/dist/extensions/WikiEditor-REL1_25-17b31b5.tar.gz

expose 80
env HOME=/root

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

entrypoint ["/entrypoint.sh"]
cmd ["/usr/bin/supervisord", "--nodaemon"]
