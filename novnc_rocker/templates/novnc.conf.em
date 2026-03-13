[program:novnc]
command=/usr/local/bin/novnc_start.sh @(novnc_port - 2000)
# --cert /root/self.pem --ssl-only
autorestart=true