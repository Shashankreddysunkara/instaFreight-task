#!/usr/bin/env bash
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

export VER=0.12.1
wget https://github.com/prometheus/mysqld_exporter/releases/download/v${VER}/mysqld_exporter-${VER}.linux-amd64.tar.gz
tar xvf mysqld_exporter-${VER}.linux-amd64.tar.gz
sudo mv  mysqld_exporter-${VER}.linux-amd64/mysqld_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/mysqld_exporter


rm -rf mysqld_exporter-${VER}.linux-amd64
rm mysqld_exporter-${VER}.linux-amd64.tar.gz

sudo chown root:prometheus /etc/.mysqld_exporter.cnf

sudo tee /etc/systemd/system/mysql_exporter.service &>/dev/null << EOF
[Unit]
Description=Prometheus MySQL Exporter
After=network.target
User=prometheus
Group=prometheus

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter \
--config.my-cnf /etc/.mysqld_exporter.cnf \
--collect.global_status \
--collect.info_schema.innodb_metrics \
--collect.auto_increment.columns \
--collect.info_schema.processlist \
--collect.binlog_size \
--collect.info_schema.tablestats \
--collect.global_variables \
--collect.info_schema.query_response_time \
--collect.info_schema.userstats \
--collect.info_schema.tables \
--collect.perf_schema.tablelocks \
--collect.perf_schema.file_events \
--collect.perf_schema.eventswaits \
--collect.perf_schema.indexiowaits \
--collect.perf_schema.tableiowaits \
--collect.slave_status \
--web.listen-address=0.0.0.0:9104

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable mysql_exporter
sudo systemctl start mysql_exporter
