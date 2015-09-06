#! /bin/bash
# Parse a support-core plugin -style txt file as specification for jenkins plugins to be installed
# in the reference directory, so user can define a derived Docker image with just :
#
# FROM jenkins
# COPY plugins.txt /plugins.txt
# RUN /usr/share/jenkins/plugins.sh /plugins.txt
#

REF=/usr/share/jenkins/ref/plugins
mkdir -p $REF

while read spec; do
    plugin=(${spec//:/ });
    echo Downloading plugin $plugin
    export cmd="curl -L ${JENKINS_UC}/download/plugins/${plugin[0]}/${plugin[1]}/${plugin[0]}.hpi -o $REF/${plugin[0]}.hpi"
    if $cmd && \
      ls -l $REF/${plugin[0]}.hpi && file $REF/${plugin[0]}.hpi | egrep "Zip archive|Microsoft OOXML"
      # for mercurial.hpi it reported Microsoft OOXML
    then
      echo ${plugin[0]}.hpi seems to be a Zip archive
    else
      echo "Downloading via '${cmd}' failed"
      exit 3
    fi
done  < $1
