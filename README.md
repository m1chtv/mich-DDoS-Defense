# 🛡️ Advanced DDoS Defense Script

A production-grade, systemd-compatible, error-handled Bash script to secure your Ubuntu server against DDoS attacks using multiple hardened layers: `iptables`, `ufw`, `nginx`, and `fail2ban`.

---

## ⚙️ Features

- 🔐 TCP/UDP port protection via `iptables`
- 🌐 HTTP rate-limiting via `nginx` with `limit_req_zone`
- 🔒 SSH & HTTP brute-force protection via `fail2ban`
- 🔁 Fully restart-safe: persistent firewall rules via `iptables-persistent`
- 🧠 Intelligent error handling with full output tracing
- 🚫 Built-in `reset` command to remove all protections
- ⚡ Systemd-ready: no TTY dependencies or interactive blocking

---

## 📦 What It Does

| Layer         | Protection Type                      |
|---------------|---------------------------------------|
| iptables      | SYN flood, UDP spam, connection limit |
| ufw           | Global firewall rule hardening        |
| nginx         | HTTP request rate throttling (1 r/s)  |
| fail2ban      | Auto-ban on failed logins / flooding  |
| persistent    | All iptables rules survive reboots    |

---

## 🧪 Usage Menu

When run, the script prompts you to choose:

1. Apply iptables Protection
2. Apply UFW Firewall Hardening
3. Enable Nginx HTTP Rate Limiting
4. Setup fail2ban
5. Apply ALL protections
6. Reset everything

   
---

## 🧠 Notes

- Compatible with Ubuntu 18.04+
- Assumes Nginx is installed and active
- `iptables-persistent` is installed automatically
- Port is prompted only for actions 1–5
- Reset fully cleans up all firewall and rate-limiting rules

---

## 🧯 Reset Option

Option 6 allows a clean rollback:
- Flushes all iptables rules
- Disables and resets UFW
- Removes Nginx rate-limit config
- Stops `fail2ban`
