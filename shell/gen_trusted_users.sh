#!/bin/bash -v

trustedusers="$*"
dirname=`dirname $0`
echo "RSA-Schlüssel erstellen für Benutzer $trustedusers"

for user in $trustedusers
do
  echo user is $user
  verzeichnis="$dirname/../hieradata/private/$user"
  if [ -d $verzeichnis ]
  then
    pwd
    echo Verzeichnis $verzeichnis schon vorhanden
  else
    echo "Verzeichnis $verzeichnis & Schlüssel muss erstellt werden"
    mkdir -p $verzeichnis
    ssh-keygen -f $verzeichnis/id_rsa -N '' 
  fi
done