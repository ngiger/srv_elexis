FROM jenkins:1.609.3

# The following sample Dockerfile uses this option to force use of HTTPS with a certificate included in the image
# COPY https.pem /var/lib/jenkins/cert
# COPY https.key /var/lib/jenkins/pk
# ENV JENKINS_OPTS --httpPort=-1 --httpsPort=8083 --httpsCertificate=/var/lib/jenkins/cert --httpsPrivateKey=/var/lib/jenkins/pk
# EXPOSE 8083

USER root
RUN apt-get update && apt-get install -y ruby vim maven xvfb ssmtp file

ADD plugins.txt /usr/share/jenkins/ref/

# docker run -p 8080:8080 -p 50000:50000 jenkins
# docker run -p 8080:8080 -p 50000:50000 -v /opt/jenkins_home_test:/var/jenkins_home --name=jenkins -u 1002 --rm=true jenkins
RUN git config --global user.name "Jenkins"
RUN git config --global user.email "Jenkins@`hostname -f`"

ADD plugins.sh /usr/local/bin/plugins.sh
RUN mkdir -p /usr/share/jenkins/ref/plugins && cd /usr/share/jenkins/ref/plugins && wget http://updates.jenkins-ci.org/download/plugins/role-strategy/latest/role-strategy.hpi
RUN /usr/local/bin/plugins.sh      /usr/share/jenkins/ref/plugins.txt

# Für rückwärts kompatibilität mit Jenkins via puppet anfang 2015
RUN /bin/ln -s /var/jenkins_home /home/jenkins && /bin/chown -R jenkins:jenkins /usr/share/jenkins


# drop back to the regular jenkins user - good practice
USER jenkins
# s.a. https://jenkins.elexis.info/jenkins/systemInfo für plugins-versionen