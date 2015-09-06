FROM  debian:jessie
MAINTAINER Niklaus Giger <niklaus.giger@member.fsf.org>

ENV LANG en_US.UTF-8
ENV DEBIAN_FRONTEND noninteractive

CMD ["/sbin/my_init"]
VOLUME "/data"

RUN \
    echo "Acquire::Languages \"none\";\nAPT::Install-Recommends \"true\";\nAPT::Install-Suggests \"false\";" > /etc/apt/apt.conf &&\
    echo "Europe/Bern" > /etc/timezone && dpkg-reconfigure tzdata &&\
    apt-get -q -y update &&\
    apt-get install -y locales-all &&\
    apt-get install -y aria2 nginx-light graphviz graphviz-dev mysql-client mysql-server \
        php5-fpm \
        php5-mysql \
        php5-imagick \
        php5-mcrypt \
        php5-curl \
        php5-cli \
        php5-memcache \
        php5-intl \
        php5-gd \
        php5-xdebug \
        php5-gd \
        php5-imap \
        php-mail \
        php-pear \
        unzip \
        php-apc &&\
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD nginx-site.conf /etc/nginx/sites-available/default

RUN \
    cd /tmp && aria2c -s 4 http://releases.wikimedia.org/mediawiki/1.25/mediawiki-1.25.2.tar.gz &&\
    mkdir /usr/share/mediawiki &&\
    tar xvzf /tmp/mediawiki-1.25.2.tar.gz --strip-components=1 -C /usr/share/mediawiki &&\
    rm -rf /usr/share/mediawiki/extensions /usr/share/mediawiki/images /tmp/mediawiki-1.25.2.tar.gz

RUN apt-get update && apt-get install -y curl

ADD add_extension.sh /usr/local/bin/add_extension.sh
ADD LocalSettings.php /usr/share/mediawiki/LocalSettings.php


RUN /usr/local/bin/add_extension.sh BlockandNuke      https://extdist.wmflabs.org/dist/extensions/BlockAndNuke-REL1_25-f01f9b7.tar.gz
RUN /usr/local/bin/add_extension.sh Collection        https://extdist.wmflabs.org/dist/extensions/Collection-REL1_25-d898236.tar.gz
RUN /usr/local/bin/add_extension.sh ConfirmEdit       https://extdist.wmflabs.org/dist/extensions/ConfirmEdit-REL1_25-48cc81c.tar.gz
RUN /usr/local/bin/add_extension.sh LanguageSelector  https://extdist.wmflabs.org/dist/extensions/LanguageSelector-REL1_25-d230e55.tar.gz
RUN /usr/local/bin/add_extension.sh Nuke              https://extdist.wmflabs.org/dist/extensions/Nuke-REL1_25-e18b127.tar.gz
RUN /usr/local/bin/add_extension.sh Vector            https://extdist.wmflabs.org/dist/extensions/Vector-REL1_25-8c5d979.tar.gz
RUN /usr/local/bin/add_extension.sh WikiEditor        https://extdist.wmflabs.org/dist/extensions/WikiEditor-REL1_25-17b31b5.tar.gz

# Todo: why?
# RUN /usr/bin/php /usr/share/mediawiki/maintenance/update.php --conf /usr/share/mediawiki/LocalSettings.php

# require_once("$IP/extensions/BlockAndNuke/BlockandNuke.php");
# require_once("$IP/extensions/Collection/Collection.php" );
# require_once("$IP/extensions/ConfirmEdit/ConfirmEdit.php" );
# require_once("$IP/extensions/LanguageSelector/LanguageSelector.php" );
# require_once "$IP/extensions/Nuke/Nuke.php";
# require_once("$IP/extensions/Vector/Vector.php" );
# require_once("$IP/extensions/WikiEditor/WikiEditor.php" );
#
# RUN \
#     mkdir -p /data /data/conf /data/images /data/extensions /data/backup &&\
#     ln -s /data/images /usr/share/mediawiki/images &&\
#     ln -s /data/extensions /usr/share/mediawiki/extensions &&\
#     chown -R www-data /usr/share/mediawiki/images &&\
#     touch /data/conf/LocalSettings.php && ln -s /data/conf/LocalSettings.php /usr/share/mediawiki && rm /data/conf/LocalSettings.php
#
# ADD docker-entrypoint.sh /etc/rc.local
# ADD backup-mysql.sh /etc/cron.daily/backup-mysql
#
# RUN sed -i "s/&&cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini &&\
#     php5dismod xdebug &&\
#     mkdir -p /data/images &&\
#     chown www-data /data/images &&\
#     chmod +x /etc/rc.local &&\
#     chmod +x /etc/cron.daily/backup-mysql
# EXPOSE 80
# Expose port 27017 from the container to the host
#EXPOSE 27017

# Set usr/bin/mongod as the dockerized entry-point application
#ENTRYPOINT ["/usr/bin/mongod"]