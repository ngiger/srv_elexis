#!/bin/bash -v
# Copyright by Niklaus Giger niklaus.giger@member.fsf.org
name=${1:-noName}
source=${2:-noSource}
doc_root=${3:-/usr/share/mediawiki}

# Fetch code to tmp
/usr/bin/curl -o /tmp/${name}.tar.gz ${source}
# Make deploy dir
/bin/mkdir -p ${doc_root}/extensions/${name}
# Unpack code to Extensions dir
/bin/tar -xzf /tmp/${name}.tar.gz -C ${doc_root}/extensions/${name} --strip-components=1
# sync db
# /usr/bin/php ${doc_root}/maintenance/update.php --conf ${doc_root}/LocalSettings.php
