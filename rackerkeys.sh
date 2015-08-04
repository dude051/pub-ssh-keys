#!/usr/bin/env bash
set -e

# Variables
RACKUSER="rack"
RACKHOME="/home/rack"

# Require script to be run via sudo, but not as root
if [[ $EUID -ne 0 ]]; then
    echo "Script must be run with sudo privilages!"
    exit 1
elif [[ $EUID = $UID && "$SUDO_USER" = "" ]]; then
    echo "Script must be run as current user via 'sudo', not as the root user!"
    exit 1
fi

# Add and configure rack user access
if getent passwd $RACKUSER > /dev/null; then
	echo "Rackspace Management User already exists...Skipping"
else
	echo -n "Adding the Rackspace Management User..."
	useradd -m -d $RACKHOME $RACKUSER
	echo "Done"
fi

echo -n "Configuring SSH keys for access..."
mkdir -p $RACKHOME/.ssh
curl -s -o $RACKHOME/.ssh/authorized_keys.md5sum https://raw.githubusercontent.com/rax-brazil/pub-ssh-keys/master/authorized_keys.md5sum
curl -s -o $RACKHOME/.ssh/authorized_keys https://raw.githubusercontent.com/rax-brazil/pub-ssh-keys/master/authorized_keys
(cd $RACKHOME/.ssh && md5sum -c authorized_keys.md5sum)
echo "Done"

echo -n "Correcting SSH configuration permissions..."
chmod 600 $RACKHOME/.ssh/authorized_keys
chmod 500 $RACKHOME/.ssh
chown -R $RACKUSER:$RACKUSER $RACKHOME/.ssh
echo "Done"

if [ -f $RACKHOME/rack.cron ]; then
	echo "Crontab already configured for updates...Skipping"
else
	echo -n "Adding crontab entry for continued updates..."
	echo "*/25 * * * * wget -O /home/rack/.ssh/authorized_keys https://raw.githubusercontent.com/rax-brazil/pub-ssh-keys/master/authorized_keys" > $RACKHOME/rack.cron
	crontab -u $RACKUSER $RACKHOME/rack.cron
	echo "Done"
fi

if [ -f /etc/sudoers.d/rack-user ]; then
	echo "Sudo already configured for Rackspace Management User...Skipping"
else
	echo -n "Configuring sudo for Rackspace Management User..."
	echo "# Rackspace user allowed sudo access" > /etc/sudoers.d/rack-user
	echo "$RACKUSER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/rack-user
	echo "" >> /etc/sudoers.d/rack-user
	chmod 440 /etc/sudoers.d/rack-user
	echo "Done"
fi
