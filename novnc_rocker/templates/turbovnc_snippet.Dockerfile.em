ARG TURBOVNC_VERSION=3.1
ARG VIRTUALGL_VERSION=3.1.4

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qy --no-install-recommends \
        ca-certificates \
        curl \
        lubuntu-desktop \
        mesa-utils \
        libegl-mesa0 \
        supervisor \
        xauth \
        adwaita-icon-theme \
        hicolor-icon-theme \
        breeze-icon-theme \
        papirus-icon-theme \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
    curl -fsSL -O https://github.com/TurboVNC/turbovnc/releases/download/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
        -O https://github.com/VirtualGL/virtualgl/releases/download/${VIRTUALGL_VERSION}/virtualgl_${VIRTUALGL_VERSION}_amd64.deb \
    && dpkg -i --force-depends *.deb \
    && rm -f /tmp/*.deb

# Keep vnc content out of
RUN echo '$vncUserDir = "/tmp/@(vnc_user)-vnc";' >> /etc/turbovncserver.conf
# One less file in home to avoid cluttering the home directory
ENV XAUTHORITY "/tmp/@(vnc_user)-vnc/.Xauthority"
# RUN echo '$xstartup = "/tmp/@(vnc_user)-vnc/xstartup.turbovnc;' >> /etc/turbovncserver.conf

# TODO(tfoote) authentication
# RUN echo testpass | /opt/TurboVNC/bin/vncpasswd -f > ~/@(vnc_user)-vnc/passwd && chmod -R 600 ~/@(vnc_user)-vnc/passwd
# TODO(tfoote) needed maybe too? && chown -R @(vnc_user) /tmp/@(vnc_user)-vnc/passwd

RUN mkdir -p /root/.supervisor/conf.d

COPY supervisor.conf /root/.supervisor
COPY turbovnc.conf /root/.supervisor/conf.d

## Make sure we're in lxqt. gnome-session will win if it's installed in the image.
RUN update-alternatives --set x-session-manager /usr/bin/startlxqt

# Wrapper script: find the TurboVNC port from its log and start noVNC proxy
RUN printf '#!/bin/sh\n\
for i in $(seq 1 30); do\n\
  PORT=$(grep -rh "Listening for VNC connections on TCP port" /tmp/*-vnc/*.log 2>/dev/null | tail -1 | awk "{print \\$NF}")\n\
  [ -n "$PORT" ] && break\n\
  sleep 1\n\
done\n\
echo "noVNC connecting to VNC port $PORT"\n\
exec /opt/noVNC/utils/novnc_proxy --vnc localhost:${PORT} --listen $1\n' > /usr/local/bin/novnc_start.sh \
    && chmod +x /usr/local/bin/novnc_start.sh

# Custom xstartup: bypass xinitrc and explicitly set VNC xauth to avoid
# conflict with the host XAUTHORITY injected by rocker's --x11 extension
RUN printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nexport XAUTHORITY="/tmp/@(vnc_user)-vnc/.Xauthority"\nsetxkbmap es\nexec /usr/bin/startlxqt\n' > /opt/TurboVNC/bin/xstartup.turbovnc \
    && chmod +x /opt/TurboVNC/bin/xstartup.turbovnc

RUN echo 'Hidden=True' >> /etc/xdg/autostart/lxqt-xscreensaver-autostart.desktop
RUN echo 'Hidden=True' >> /etc/xdg/autostart/lxqt-powermanagement.desktop
RUN echo 'Hidden=True' >> /etc/xdg/autostart/upg-notifier-autostart.desktop
RUN echo 'Hidden=True' >> /etc/xdg/autostart/nm-tray-autostart.desktop
RUN echo 'Hidden=True' >> /etc/xdg/autostart/nm-applet.desktop

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]