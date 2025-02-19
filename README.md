# Prometheus Installation Script

This script automates the installation and setup of Prometheus on a Linux system as part of the Observability configuration.

## Prerequisites

- A Linux-based operating system (e.g., Ubuntu)
- `sudo` privileges

## Usage

To run the script, execute the following command in your terminal:

```bash
./prometheus_setup.sh [PROMETHEUS_VERSION]
```

- [PROMETHEUS_VERSION] (optional): The version of Prometheus to install. If not provided, the script will install the latest version.

## Script Explanation
1. Update the System
```bash
sudo apt-get update
sleep 1
```
This updates the package lists for upgrades and new package installations.

2. Create Prometheus User
```bash
sudo useradd --no-create-home --shell /bin/false prometheus
```
This creates a new system user named `prometheus` without a home directory and with no login shell for security purposes.

3. Create Directories for Prometheus
```bash
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
```
These commands create directories for Prometheus configuration files and data storage.

4. Change Permissions
```bash
sudo chown prometheus:prometheus /etc/prometheus/
sudo chown prometheus:prometheus /var/lib/prometheus/
```
These commands change the ownership of the created directories to the `prometheus` user.

5. Determine the Prometheus Version
```bash
PROMETHEUS_VERSION=${1:-latest}
```
This sets the Prometheus version to the first argument provided to the script, or defaults to `latest` if no argument is provided.

6. Determine the Download URL
```bash
if [ "$PROMETHEUS_VERSION" = "latest" ]; then
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64.tar.gz | cut -d '"' -f 4)
else
    DOWNLOAD_URL="https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz"
fi
```
This block determines the download URL for the Prometheus tarball based on the specified version.

7. Download Prometheus
```bash
wget "$DOWNLOAD_URL"
sleep 10
```
This downloads the Prometheus tarball from the determined URL.

8. Extract the Tarball
```bash
sudo tar -xvf prometheus-"$PROMETHEUS_VERSION".linux-amd64.tar.gz
sleep 2
cd prometheus-"$PROMETHEUS_VERSION".linux-amd64/ || exit
```
This extracts the downloaded tarball and navigates into the extracted directory.

9. Move Executables
```bash
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/
```
These commands move the `Prometheus executable` and the `promtool` utility to `/usr/local/bin/`.

10. Update Permissions
```bash
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
```
These commands change the ownership of the moved files to the `prometheus` user.

11. Move Configuration Files
```bash
sudo cp -r consoles/ /etc/prometheus
sudo cp -r console_libraries/ /etc/prometheus
sudo cp prometheus.yaml /etc/prometheus
```
These commands move the configuration files and directories to `/etc/prometheus`.

12. Update Permissions for Configuration Files
```bash
sudo chown -R prometheus:prometheus /etc/prometheus/consoles/
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries/
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yaml
```
These commands change the ownership of the configuration files and directories to the `prometheus` user.

13. Clean Up
```bash
cd .. && rm -rf prometheus-"$PROMETHEUS_VERSION".linux-amd64.tar.gz prometheus-"$PROMETHEUS_VERSION".linux-amd64
```
This removes the downloaded tarball and the extracted directory to clean up unnecessary files.

14. Create Prometheus Service
```bash
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
```
This block creates a systemd service file for Prometheus.

15. Start and Enable Prometheus Service
```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
```
These commands reload the systemd daemon, start the Prometheus service, and enable it to start on boot.

## Conclusion
This script automates the entire process of installing and setting up Prometheus on a Linux system. By following the steps outlined in this README, you can easily deploy Prometheus and start monitoring your systems.