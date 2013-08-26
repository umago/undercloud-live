# undercloud-live

Tools and scripts to build an undercloud Live CD and configure an already
running Fedora 19 x86_64 system into an undercloud.  The script is meant to be run on
physical hardware.  However, it can also be used on a vm.  When using a vm you need to make
sure that the vm you intend to configure as a undercloud has been configured to
use nested kvm (see [here][1] and [here][2]).

To get started, clone this repo to your home directory:

    $ cd
    $ git clone https://github.com/slagle/undercloud-live.git

## bin/undercloud.sh
This script is run as the current user to configure the current system into an
undercloud.

The undercloud makes use of the default libvirtd network of 192.168.122.0/24.
If you want to change the network (e.g., you're running the script on a vm
whose host is already using 192.168.122.0/24), edit
undercloud-live/bin/custom.sh, and then source that file:

    # Edit undercloud-live/bin/custom-network.sh, and set the environment
    # variables in the file to your desired settings.
    $ vi undercloud-live/bin/custom-network.sh
    $ source undercloud-live/bin/custom-network.sh

Run the undercloud script itself:

    $ undercloud-live/bin/undercloud.sh

The script logs to ~/.undercloud-live/undercloud.log.  If there is an error
applying one of the diskimage-builder elements, you will see a prompt to
continue or not.  This is for debugging purposes.

Once the script has completed, you should have a functioning undercloud.  At
this point, you would move onto the next steps of building images and
deploying an overcloud.  These steps are also scripted in the
undercloud-images.sh and undercloud-deploy-overcloud.sh scripts.  You can
just run these scripts if you prefer to do that instead:

    $ undercloud-live/bin/undercloud-images.sh
    $ undercloud-live/bin/undercloud-deploy-overcloud.sh

NOTE: undercloud-images.sh will not build images if the files already exist under
/opt/stack/images.  If you already have image files you want to use on the
undercloud, just copy them into /opt/stack/images.


### Prerequisites
* Only works on Fedora 19 x86_64
* sudo as root ability

### Caveats
* undercloud.sh deploys software from git repositories and directly from PyPi.
  This will be updated to use rpm's at a later date.
* The git repositories that are checked out under /opt/stack are set to
  checkout specific hashes.  Some of these hashes are specified in
  bin/undercloud-install.sh.  Others are specified in an undercloud-live branch
  of a fork of tripleo-image-elements at 
  https://github.com/slagle/tripleo-image-elements.git.  The undercloud-live
  branch there sets specific hashes to use via the source-repository interface.
* If you reboot the undercloud system, you will need to rerun
  bin/undercloud-network.sh
* The firewalld service will be shutdown by undercloud.sh.  There's currently a
  bug in the iptables configuration that prevents the overcloud from pxe booting that is still
  being investigated.
* SELinux is set to Permissive mode.  Otherwise, rabbitmq-server will not
  start.  
  See: https://bugzilla.redhat.com/show_bug.cgi?id=998682  
  Note: we will be switching to use qpid soon

## kickstart/fedora-undercloud-livecd.ks
kickstart file that can be used to build an undercloud Live CD.

1. install fedora-kickstarts and livecd-tools if needed
1. livecd-creator --verbose  --fslabel=Fedora-Undercloud-LiveCD --cache=/var/cache/yum/x86_64/19 --releasever=19 --config=/path/to/undercloud-live/kickstart/fedora-undercloud-livecd.ks

This will produce a Fedora-Undercloud-LiveCD.iso file in the current directory.
To test it simply run:

    qemu-kvm -m 2048 Fedora-Undercloud-LiveCD.iso 
(you can run it with less ram, but it will be quite a bit slower)

## Running the live cd

To use the live cd, follow the steps below.

1. Boot the live cd on physical hardware or in a vm with at least 4gb of ram.
1. The libvirtd service on the undercloud uses the default network of
   192.168.122.0/24.  If this is already in use in your enviornment, you need
   to change it.  Here's an example of doing that if you wanted to switch the
   subnet to 123 instead of 122:

    # run these commands as root
    sed -i "s/122/123/g" /etc/libvirt/qemu/networks/default.xml
    systemctl restart libvirtd
    virsh net-destroy default
    virsh net-start default
1. Open a terminal and switch to the stack user:
    su -
    su - stack
1. Source the undercloud configuration
    source undercloudrc

From here, you can use all the normal openstack clients to interact with the
running undercloud services.

To get going on deploying an overcloud, you will want to build images and start
the overcloud.  There are scripts to do these pieces as well, but we may change
that into just documentation instructions so that users get the full experience
of setting up an overcloud themselves.  The scripts are here:
    /opt/stack/undercloud-live/bin/undercloud-images.sh
    /opt/stack/undercloud-live/bin/undercloud-deploy-overcloud.sh




# References

[1]: http://www.server-world.info/en/note?os=Fedora_19&p=kvm&f=8
[2]: https://fedoraproject.org/wiki/QA:Testcase_KVM_nested_virt
