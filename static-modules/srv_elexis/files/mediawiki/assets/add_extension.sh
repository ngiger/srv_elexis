#!/bin/bash -v
set -e
# Copyright by Niklaus Giger niklaus.giger@member.fsf.org
name=${1:-noName}
source=${2:-noSource}
doc_root=${3:-/srv/mediawiki}
cd $doc_root
mkdir -p downloaded_extensions
# Fetch code to tmp
/usr/bin/curl --silent -o downloaded_extensions/${name}.tar.gz ${source}
# Make deploy dir
/bin/mkdir -p ${doc_root}/extensions/${name}
# Unpack code to Extensions dir
/bin/tar -xzf downloaded_extensions/${name}.tar.gz -C ${doc_root}/extensions/${name} --strip-components=1
# sync db
# /usr/bin/php ${doc_root}/maintenance/update.php --conf ${doc_root}/LocalSettings.php
