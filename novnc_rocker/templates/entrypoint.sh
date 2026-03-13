#!/bin/sh
if [ "$(id -u)" -ne 0 ]; then
  sudo -E /usr/bin/supervisord -c /root/.supervisor/supervisor.conf &
else
  /usr/bin/supervisord -c /root/.supervisor/supervisor.conf &
fi
exec "$@"
