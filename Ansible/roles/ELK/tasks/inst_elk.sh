#!/usr/bin/env bash

export DEBIAN_FRONTEND="noninteractive"

ELK_VERSION="7.6.0"

# update apt
apt-get update --quiet
apt-get install -y unzip ifupdown git apt-transport-https default-jre --quiet

echo "Java version"
java -version
[ -z $JAVA_HOME ] && echo "JAVA_HOME not set" || echo "JAVA_HOME is ${JAVA_HOME}"

# install the Elastic PGP Key and repo
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list

apt-get update --quiet
echo "[*] Installing Elastic Search"
apt-get install --quiet -y elasticsearch=$ELK_VERSION 
echo "[+] Done Installing Elastic Search"

# Install Kibana
echo "[*] Installing Kibana"
apt-get install --quiet -y kibana=$ELK_VERSION 
echo "[*] Done Installing Kibana"


# install Logstash
echo "[*] Installing Logstash"
apt-get install  --quiet -y logstash=1:$ELK_VERSION-1 
# apt-get install --quiet -y filebeat
echo "[+] Done Installing Logstash"
