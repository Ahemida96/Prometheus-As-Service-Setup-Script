#!/bin/bash

# Update the system
sudo apt-get update
sleep 1

# Create prometheus user
sudo useradd --no-create-home --shell /bin/false prometheus

# Create dir in /etc for prometheus configuration files
sudo mkdir /etc/prometheus

# Create dir in /var/lib to store prometheus data
sudo mkdir /var/lib/prometheus

# Change permissions to prometheus user for config and data directories
sudo chown prometheus:prometheus /etc/prometheus/
sudo chown prometheus:prometheus /var/lib/prometheus/

# Get the Prometheus version from the first argument, default to latest if not provided
PROMETHEUS_VERSION=${1:-latest}

# Determine the download URL based on the version
if [ "$PROMETHEUS_VERSION" = "latest" ]; then
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64.tar.gz | cut -d '"' -f 4)
    PROMETHEUS_VERSION=$(echo "$DOWNLOAD_URL" | grep -oP 'prometheus-\K[0-9.]+(?=\.linux-amd64\.tar\.gz)')
else
    DOWNLOAD_URL="https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"
fi

# Download Prometheus tar file
wget "$DOWNLOAD_URL"
sleep 10

# Untar the file and move inside the directory
sudo tar -xvf prometheus-"$PROMETHEUS_VERSION".linux-amd64.tar.gz
sleep 2
cd prometheus-"$PROMETHEUS_VERSION".linux-amd64/ || exit

: '
List of files and direcroties inside the prometheus directory
prometheus -> Executable file
prometheus.yaml -> configurations file
promtool -> command-line utility helps verify if configurations are acceptable
consoles & console_libraries -> Dashboard Virtualization
'

# Move prometheus executable & promtool files to /usr/local/bin/
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/

# Update the permissions
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Move prometheus.yaml, consoles & console_libraries to /etc/prometheus
sudo cp -r consoles/ /etc/prometheus
sudo cp -r console_libraries/ /etc/prometheus
sudo cp prometheus.yaml /etc/prometheus

# Update the permissions
sudo chown -R prometheus:prometheus /etc/prometheus/consoles/
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries/
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yaml

sleep 5

# Delete any remaining files from your home directory that are no longer required.
cd .. && rm -rf prometheus-"$PROMETHEUS_VERSION".linux-amd64.tar.gz prometheus-"$PROMETHEUS_VERSION".linux-amd64

# Create service file for prometheus
sudo bash -c 'cat <<EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF'

# Reload system daemon and start prometheus service
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

echo "Prometheus Installation Completed! "