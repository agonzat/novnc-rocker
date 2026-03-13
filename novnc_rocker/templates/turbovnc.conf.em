[program:turbovnc]
command=/opt/TurboVNC/bin/vncserver  -SecurityTypes None -localhost -fg -geometry 1280x720
autorestart=true
user=@(vnc_user)
environment=USER="@(vnc_user)",HOME="@(vnc_user_home)",TVNC_WM="x-session-manager",XAUTHORITY="/tmp/@(vnc_user)-vnc/.Xauthority",VGL_DISPLAY="%(ENV_VGL_DISPLAY)s",VGL_COMPRESS="0",VGL_READBACK="async"