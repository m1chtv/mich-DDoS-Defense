#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

run_or_exit() {
  "$@" || { echo -e "${RED}[!] Failed: $*${RESET}"; exit 1; }
}

read_port() {
  read -p "📍 Enter target port (e.g. 80): " PORT
  if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
    echo -e "${RED}[!] Invalid port.${RESET}"
    exit 1
  fi
}

iptables_protection() {
  echo -e "${GREEN}[+] Setting iptables rules...${RESET}"
  run_or_exit sudo iptables -A INPUT -p tcp --syn --dport "$PORT" -m connlimit --connlimit-above 20 --connlimit-mask 32 -j DROP
  run_or_exit sudo iptables -A INPUT -p udp --dport "$PORT" -m limit --limit 10/second --limit-burst 20 -j ACCEPT
  run_or_exit sudo iptables -A INPUT -p udp --dport "$PORT" -j DROP
  run_or_exit sudo iptables -A INPUT -p tcp --dport "$PORT" -m state --state NEW -m recent --set
  run_or_exit sudo iptables -A INPUT -p tcp --dport "$PORT" -m state --state NEW -m recent --update --seconds 10 --hitcount 30 -j DROP

  echo -e "${GREEN}[+] Saving iptables rules...${RESET}"
  run_or_exit sudo apt install -y iptables-persistent
  run_or_exit sudo netfilter-persistent save
}

ufw_harden() {
  echo -e "${GREEN}[+] Configuring UFW...${RESET}"
  run_or_exit sudo ufw default deny incoming
  run_or_exit sudo ufw default allow outgoing
  run_or_exit sudo ufw allow "$PORT"/tcp
  run_or_exit sudo ufw --force enable
}

nginx_rate_limit() {
  echo -e "${GREEN}[+] Enabling Nginx rate limiting...${RESET}"
  sudo tee /etc/nginx/conf.d/rate_limit.conf > /dev/null <<EOF
limit_req_zone \$binary_remote_addr zone=req_limit_per_ip:10m rate=1r/s;

server {
    listen $PORT default_server;
    server_name localhost;

    location / {
        limit_req zone=req_limit_per_ip burst=5 nodelay;
        return 200 "Protected\n";
    }
}
EOF
  run_or_exit sudo nginx -t
  run_or_exit sudo systemctl reload nginx
}

fail2ban_setup() {
  echo -e "${GREEN}[+] Configuring fail2ban...${RESET}"
  run_or_exit sudo apt install -y fail2ban
  sudo tee /etc/fail2ban/jail.d/custom.conf > /dev/null <<EOF
[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
bantime = 600
maxretry = 3

[nginx-http-auth]
enabled = true
port = $PORT
logpath = /var/log/nginx/access.log
bantime = 600
maxretry = 5
EOF
  run_or_exit sudo systemctl restart fail2ban
}

reset_all() {
  echo -e "${RED}[!] Resetting firewall and services...${RESET}"
  run_or_exit sudo iptables -F
  run_or_exit sudo iptables -X
  run_or_exit sudo ufw --force disable
  run_or_exit sudo rm -f /etc/nginx/conf.d/rate_limit.conf
  run_or_exit sudo systemctl reload nginx
  run_or_exit sudo systemctl stop fail2ban
  echo -e "${GREEN}[✔] All protections removed.${RESET}"
}

main() {
  echo -e "${GREEN}Advanced DDoS Defense — Choose Action:${RESET}"
  echo "1) Apply iptables Protection"
  echo "2) Apply UFW Firewall Hardening"
  echo "3) Enable Nginx HTTP Rate Limiting"
  echo "4) Setup fail2ban"
  echo "5) Apply ALL protections"
  echo "6) Reset everything"
  read -p "Select [1-6]: " CHOICE

  if [[ "$CHOICE" != "6" ]]; then
    read_port
  fi

  case "$CHOICE" in
    1) iptables_protection ;;
    2) ufw_harden ;;
    3) nginx_rate_limit ;;
    4) fail2ban_setup ;;
    5)
      iptables_protection
      ufw_harden
      nginx_rate_limit
      fail2ban_setup
      ;;
    6) reset_all ;;
    *) echo -e "${RED}[!] Invalid option.${RESET}" && exit 1 ;;
  esac
}

main
