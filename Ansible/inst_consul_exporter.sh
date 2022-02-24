#!/usr/bin/env bash

useradd --no-create-home --shell /bin/false consul_exporter

wget https://github.com/prometheus/consul_exporter/releases/download/v0.6.0/consul_exporter-0.6.0.linux-amd64.tar.gz
tar xvf consul_exporter-0.6.0.linux-amd64.tar.gz 
sudo cp consul_exporter-0.6.0.linux-amd64/consul_exporter /usr/local/bin
sudo chown consul_exporter:consul_exporter /usr/local/bin/consul_exporter



tee /etc/systemd/system/consul_exporter.service << 'EOF'
[Unit]
Description=Consul Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=consul_exporter
Group=consul_exporter
Type=simple
ExecStart=/usr/local/bin/consul_exporter --consul.server="http://localhost:8500"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start consul_exporter.service
sudo systemctl enable consul_exporter.service
