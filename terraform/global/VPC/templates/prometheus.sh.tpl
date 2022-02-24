#!/usr/bin/env bash
set -e

echo "Grabbing IPs..."
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)


tee /etc/consul.d/prometheus-9090.json > /dev/null <<"EOF"
{
  "service": {
    "id": "promcol-9090",
    "name": "promcol",
    "tags": ["promcol"],
    "port": 9090,
    "checks": [
      {
        "id": "tcp",
        "name": "TCP on port 9090",
        "tcp": "localhost:9090",
        "interval": "10s",
        "timeout": "1s"
      }
    ]
  }
}
EOF

consul reload