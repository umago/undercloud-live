#!/bin/bash

set -eux

source $HOME/undercloudrc

/opt/stack/tripleo-incubator/scripts/setup-passwords -o
source tripleo-passwords

export OVERCLOUD_LIBVIRT_TYPE=qemu

heat stack-create -f /opt/stack/tripleo-heat-templates/overcloud.yaml \
    -P "AdminToken=${OVERCLOUD_ADMIN_TOKEN};AdminPassword=${OVERCLOUD_ADMIN_PASSWORD};CinderPassword=${OVERCLOUD_CINDER_PASSWORD};GlancePassword=${OVERCLOUD_GLANCE_PASSWORD};HeatPassword=${OVERCLOUD_HEAT_PASSWORD};NeutronPassword=${OVERCLOUD_NEUTRON_PASSWORD};NovaPassword=${OVERCLOUD_NOVA_PASSWORD}${OVERCLOUD_LIBVIRT_TYPE}" \
    overcloud
