#!/usr/bin/env bash
set -e

echo "Grabbing IPs..."
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)


tee /etc/consul.d/ELK-9200.json > /dev/null <<"EOF"
{
  "services": [
    {
    "id": "elasticsearch-9200",
    "name": "elasticsearch",
    "tags": ["elasticsearch"],
    "address": "",
    "port": 9200,
    "checks": [
      {
        "id": "tcp",
        "name": "TCP on port 9200",
        "tcp": "localhost:9200",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  },
  {
    "id": "logstash-5044",
    "name": "logstash",
    "tags": ["logstash"],
    "address": "",
    "port": 5044,
    "checks": [
      {
        "id": "tcp",
        "name": "TCP on port 5044",
        "tcp": "localhost:5044",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  },
  {
    "id": "kibana-5601",
    "name": "kibana",
    "tags": ["kibana"],
    "address": "",
    "port": 5601,
    "checks": [
      {
        "id": "tcp",
        "name": "TCP on port 5601",
        "tcp": "localhost:5601",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  }
  ]
}
EOF

consul reload
