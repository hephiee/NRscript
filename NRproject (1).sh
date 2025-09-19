#!/bin/bash

if command -v geoip-bin &> /dev/null
then
    echo "geoip-bin is installed!"
else
    echo "geoip-bin is not installed, installing now..."
    sudo apt-get update
    sudo apt-get install -y geoip-bin
fi


if command -v tor &> /dev/null
then
    echo "Tor is installed!"
else
    echo "Tor is not installed, installing now..."
    sudo apt-get update
    sudo apt-get install -y tor
fi


if command -v sshpass &> /dev/null
then
    echo "sshpass is installed!"
else
    echo "sshpass is not installed, installing now..."
    sudo apt-get update
    sudo apt-get install -y sshpass
fi

if command -v Nipe &> /dev/null
then
    echo "Nipe is installed!"
else
    echo "Nipe is not installed, installing now..."
    sudo git clone https://github.com/htrgouvea/nipe && cd nipe
    sudo cpanm --installdeps .
    sudo cpan install Switch JSON LWP::UserAgent Config::Simple
    sudo perl nipe.pl install

fi


cd nipe
echo "checking for nipe connection"
sudo perl nipe.pl status

echo "Connecting through Nipe..."
sudo perl nipe.pl start

echo "checking for nipe connection"
sudo perl nipe.pl status
echo "your new ip and country::"
sudo perl nipe.pl status

echo "which domain/url to scan? (152.42.232.203, scanme.nmap.com, scanme2, scanme3): "
read chosenDomain

echo "connecting to server. . . "
sshpass -p "tc" ssh -t tc@192.168.227.129 << EOF

echo "connected."

echo "running nmap scan. . . "
nmap $chosenDomain > /tmp/nmap_scan_results.txt
echo "running whois lookup. . . "
whois $chosenDomain > /tmp/whois_results.txt

exit
EOF


REMOTE_SERVER="192.168.227.129" 
REMOTE_USER="tc"
REMOTE_PASS="tc"

LOCAL_LOG_DIR="/var/log"

SCAN_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

REMOTE_COMMANDS=(
  "nmap $chosenDomain > /tmp/nmap_scan_results.txt"
  "whois $chosenDomain > /tmp/whois_results.txt"
)

for cmd in "${REMOTE_COMMANDS[@]}"; do
  sshpass -p "$REMOTE_PASS" ssh -t "$REMOTE_USER@$REMOTE_SERVER" "$cmd"
done

sshpass -p "$REMOTE_PASS" scp "$REMOTE_USER@$REMOTE_SERVER:/tmp/nmap_scan_results.txt" "$LOCAL_LOG_DIR/nmap_scan_$SCAN_TIMESTAMP.txt"
sshpass -p "$REMOTE_PASS" scp "$REMOTE_USER@$REMOTE_SERVER:/tmp/whois_results.txt" "$LOCAL_LOG_DIR/whois_results_$SCAN_TIMESTAMP.txt"

echo "Scan executed on: $(date '+%Y-%m-%d %H:%M:%S')" > "$LOCAL_LOG_DIR/scan_log.txt"
echo "Domain scanned: $chosenDomain" >> "$LOCAL_LOG_DIR/scan_log.txt"
echo "Scans performed: nmap, whois" >> "$LOCAL_LOG_DIR/scan_log.txt"
