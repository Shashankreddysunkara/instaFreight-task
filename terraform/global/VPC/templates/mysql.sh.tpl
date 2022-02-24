#!/usr/bin/env bash
set -e

echo "Grabbing IPs..."
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)


tee /etc/consul.d/mysql-3306.json > /dev/null <<"EOF"
{
  "service": {
    "id": "mysql-3306",
    "name": "mysql",
    "tags": ["mysql"],
    "port": 3306,
    "checks": [
      {
        "id": "tcp",
        "name": "TCP on port 3306",
        "tcp": "localhost:3306",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  }
}
EOF

consul reload
