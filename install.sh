#!/bin/bash

# Exit on errors
set -e

# install
function install_mpd2chromecast {
    cd # go to home
    echo "Installing mpd2chromecast user:${USER} pwd:${HOME}"

    # GIT repo
    echo "Downloading mpd2chromecast..."
    rm -rf mpd2chromecast
    git clone https://github.com/dresdner353/mpd2chromecast.git

    # Purge old entries from crontab if cron is installed
    if [[ -f /usr/sbin/cron ]]
    then 
        echo "purging old crontab entries"
        # filter out existing entries
        crontab -l | sed -e '/mpd2chromecast/d' >/tmp/${USER}.cron
        # reapply filtered crontab
        crontab /tmp/${USER}.cron
    fi

    # kill any remnants of the existing scripts
    pkill -f mpd2chromecast.py
    pkill -f mpd2chromecast.sh
}

# export function for su call
export -f install_mpd2chromecast 

# main()
if [[ "`whoami`" != "root" ]]
then
    echo "This script must be run as root (or with sudo)"
    exit 1
fi

# Determine the variant and then non-root user
# only supports Volumio and moOde at present
VOLUMIO_CHECK=/usr/local/bin/volumio		
MOODE_CHECK=/usr/local/bin/moodeutl		

if [[ -f ${VOLUMIO_CHECK} ]]
then
    HOME_USER=volumio
    HOME_DIR=/home/volumio
elif [[ -f ${MOODE_CHECK} ]]
then
    HOME_USER=pi
    HOME_DIR=/home/pi
else
    echo "Cannot determine variant (volumio or moOde)"
    exit 1
fi
echo "Detected home user:${HOME_USER}"


# install packages
apt-get -y install python3-pip
pip3 install pychromecast cherrypy python-mpd2 mutagen

# install mod2chromecast
#su ${HOME_USER} -c "bash -c install_mpd2chromecast"

# systemd service
echo "Systemd steps for ~${HOME_DIR}/mpd2chromecast/mpd2chromecast.service"
cp ${HOME_DIR}/mpd2chromecast/mpd2chromecast.service /etc/systemd/system
systemctl daemon-reload
systemctl enable mpd2chromecast
systemctl restart mpd2chromecast
