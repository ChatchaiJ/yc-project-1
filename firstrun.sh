#!/bin/bash

USER="demo"

CHROME_DEB="google-chrome-stable_current_amd64.deb"
ANYDESK_DEB="anydesk_7.0.0-1_amd64.deb"
CHROME_URL="https://dl.google.com/linux/direct/${CHROME_DEB}"
ANYDESK_URL="https://download.anydesk.com/linux/${ANYDESK_DEB}"

COUNT=0
MAX_UPDATE_FAIL=30

## For some reason, when running on virtual enviroment, the first "apt-get update" failed with
## repository server resolve problem, so, this loop attempt to fix that problem.

while true; do
	if apt-get update; then
		# update success, we install unzip, and break from this infinite loop
		apt-get install unzip
		break
	else
		COUNT=$(expr ${COUNT} + 1)
		if [ ${COUNT} -lt ${MAX_UPDATE_FAIL} ]; then
			echo "$(date) -- fail to run apt-get update, wait for 10 seconds"
			sleep 10
		else
			echo "$(date) -- after ${MAX_UPDATE_FAIL} attempts, still fail, so bail out"
			exit
		fi
	fi
done

[ ! -x /bin/unzip ] && { echo "'unzip' is not available, stop here"; exit; }

FIRSTRUN_FLAG="/root/firstrun_flag"
if [ -f "${FIRSTRUN_FLAG}" ]; then
	echo "Firstrun script already run once, stop here."
	exit
else
	touch ${FIRSTRUN_FLAG}
fi

# Now do install google chrome and anydesk
cd /var/tmp

# Install Google Chrome
echo "## Install Google Chrome ##"
wget ${CHROME_URL}
if [ -f "${CHROME_DEB}" ]; then
	apt-get install -y fonts-liberation
	dpkg -i ${CHROME_DEB}
else
	echo "Something wrong, there is no '${CHROME_DEB}' file, can't install google chrome"
fi

# Install AnyDesk
echo "## Install AnyDesk ##"
wget ${ANYDESK_URL}
if [ -f "${ANYDESK_DEB}" ]; then
	dpkg -i ${ANYDESK_DEB}
else
	echo "Something wrong, there is no '${ANYDESK_DEB}' file, can't install anydesk"
fi

# Setup autologin for user 'demo'
# Assume lightdm is the 'DisplayManager'
if [ -z "$(id -u demo 2>/dev/null)" ]; then
	echo "No user demo? -- Can't configure autologin."
	exit
fi

if [ ! -d "/etc/lightdm" ]; then
	echo "Not using lightdm as Display Manager? -- Stop here."
	exit
fi

mkdir -p /etc/lightdm/lightdm.conf.d
cat <<_END_ > /etc/lightdm/lightdm.conf.d/10-autologin.conf
[SeatDefaults]
autologin-user=${USER}
autologin-user-timeout=0
_END_

# Setup auto start google-chrome for 'demo'
mkdir -p /home/${USER}/.config/autostart
cat <<_END_ > /home/${USER}/.config/autostart/google-chrom.desktop
[Desktop Entry]
Version=1.0
Name=Google Chrome
GenericName=Web Browser
Comment=Access the Internet
# Exec=/usr/bin/google-chrome-stable --password-store=basic --kiosk https://www.google.com
# Exec=/usr/bin/google-chrome-stable --password-store=basic --start-fullscreen https://www.google.com
Exec=/usr/bin/google-chrome-stable --password-store=basic https://www.google.com
StartupNotify=true
Terminal=false
Icon=google-chrome
Type=Application
Categories=Network;WebBrowser;
MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/http;x-scheme-handler/https;
Actions=new-window;new-private-window;
_END_

chown -R ${USER}:${USER} /home/${USER}/.config/autostart
