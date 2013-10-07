#!/bin/bash

set -eux

source /opt/stack/undercloud-live/bin/common.sh

# The commands in this script require a running, configured cloud.

if [ -f /opt/stack/undercloud-live/.setup ]; then
    exit
fi

sudo cp /root/stackrc $HOME/undercloudrc
source $HOME/undercloudrc

# Find the keystone unit
KEYSTONE_UNIT=`systemctl list-unit-files --type=service | grep -i keystone | awk '{print $1}'`
[ ! "$KEYSTONE_UNIT" ] && exit 1

# Ensure keystone is up before continuing on.
# Waits for up to 2 minutes.
wait_for 12 10 sudo systemctl status $KEYSTONE_UNIT

# Because keystone just still isn't up yet...
sleep 20

# Make sure we have the latest $PATH set.
source /etc/profile.d/tripleo-incubator-scripts.sh

export UNDERCLOUD_IP=192.0.2.1

if [ ! -f /root/.ssh/authorized_keys ]; then
    sudo mkdir -p /root/.ssh
    sudo chmod 7000 /root/.ssh/
    sudo touch /root/.ssh/authorized_keys
    sudo chmod 600 /root/.ssh/authorized_keys
fi
sudo bash -c "cat /home/$USER/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"

# Workaround for init-keystone
if [ ! -f /opt/stack/venvs/keystone/bin/keystone-manage ]; then
    sudo mkdir -p /opt/stack/venvs/keystone/bin/
    sudo ln -s $(which keystone-manage) /opt/stack/venvs/keystone/bin/keystone-manage
fi

init-keystone -p unset unset \
    $UNDERCLOUD_IP admin@example.com root@$UNDERCLOUD_IP

setup-endpoints $UNDERCLOUD_IP --glance-password unset \
    --heat-password unset \
    --neutron-password unset \
    --nova-password unset

keystone role-create --name heat_stack_user

# Adds default ssh key to nova
/opt/stack/tripleo-incubator/scripts/user-config

/opt/stack/tripleo-incubator/scripts/setup-neutron 192.0.2.5 192.0.2.24 192.0.2.0/24 $UNDERCLOUD_IP ctlplane

cat /opt/stack/boot-stack/virtual-power-key.pub >> ~/.ssh/authorized_keys

# Baremetal setup
# Doing this as root b/c when this script is called from systemd, the access
# to the libvirtd socket is restricted.
sudo -i /opt/stack/tripleo-incubator/scripts/create-nodes 1 2048 20 amd64 2

cat /opt/stack/boot-stack/virtual-power-key.pub >> /home/$USER/.ssh/authorized_keys

sudo touch /opt/stack/undercloud-live/.setup
