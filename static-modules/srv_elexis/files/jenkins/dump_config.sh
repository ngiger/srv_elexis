#!/bin/bash -v
set -e
export DUMP_1=/opt/backups/jenkins_config_dump1.tar.gz
export DUMP_2=/opt/backups/jenkins_config_dump2.tar.gz
export what="config.xml credentials.xml .ssh/ secrets/ users/ nodes/*/config.xml jobs/*/config.xml jobs/*/nextBuildNumber hudson*.xml plugins/*.hpi"
export JENKINS_HOME=/home/jenkins
tar --exclude-from jenkins_backup_exclusion -zcf ${DUMP_2} ${JENKINS_HOME}
cd $JENKINS_HOME
tar -acf ${DUMP_1} ${what}
