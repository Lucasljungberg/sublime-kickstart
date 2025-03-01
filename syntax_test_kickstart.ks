# SYNTAX TEST "Packages/kickstart-syntax/kickstart.sublime-syntax"

# fedora-server-vm-full.ks (rel. 1.02)
# Kickstart file to build a Fedora Server Edition VM disk image.
# The image aims to resemble as close as technically possible the
# full features of a Fedora Server Edition in a virtual machine.
#
# The image uses GPT partition type as of default in Fedora 37.
#
# At first boot it opens a text mode basic configuration screen.
#
# This kickstart file is designed to be used with ImageFactory (in Koji).
#
# To build the image locally, you need to install ImageFactory and
# various additional helpers and configuration files.
# See Fedora Server Edition user documentation tutorial.
# <- source.kickstart comment.line

# Use text mode install
text
# ^ source.kickstart meta.statement.command.kickstart

# Keyboard layouts
keyboard 'us'
#         ^ meta.argument.kickstart
#         ^ string.quoted.kickstart

# System language
lang en_US.UTF-8
#         ^ meta.argument.kickstart
#         ^ unquoted.argument.kickstart

# System timezone
# set time zone to GMT (Etcetera/UTC)
timezone Etc/UTC --utc


# Root password
rootpw --iscrypted --lock locked

# SELinux configuration
selinux --enforcing


# System bootloader configuration
bootloader --location=mbr --timeout=1 --append="console=tty1 console=ttyS0,115200n8"

# Network information
network  --bootproto=dhcp --device=link --activate --onboot=on

# Firewall configuration
firewall --enabled --service=mdns


# System services
services --enabled="sshd,NetworkManager,chronyd,initial-setup"

# Run the Setup Agent on first boot
firstboot --reconfig

# Partition Information. Use GPT by default (since Fedora 37)
# Resemble the Partitioning used for Fedora Server Install media
clearpart --all --initlabel --disklabel=gpt
reqpart --add-boot
part pv.007     --size=4000  --grow
volgroup  sysvg  pv.007
logvol / --vgname=sysvg --size=4000 --grow --maxsize=16000 --fstype=xfs --name=root --label=sysroot


# Include URLs for network installation dynamically, dependent on Fedora release
# and imagefactory runtime environment
%include fedora-repo.ks
# ^ keyword.control.include.kickstart
#        ^ meta.argument.kickstart

# Shutdown after installation
shutdown

##### begin package list #############################################
%packages --inst-langs=en # Install English versions
# ^ keyword.control.packages.kickstart
# ^ -meta.section.packages.argument.kickstart
#           ^ packages.argument.kickstart unquoted.argument.kickstart
#                         ^ comment.line.kickstart
@server-product
# ^ string.unquoted.packages.group.kickstart
@core

# Standard Fedora Package Groups
## dracut-config-generic  ## included in =core=
glibc-all-langpacks
initial-setup
kernel-core
-dracut-config-rescue
-generic-release*
# <- keyword.operator.logical.not.kickstart
#               ^ variable.language.special.wildcard.kickstart

-initial-setup-gui
-kernel
-linux-firmware
-plymouth
# pulled in by @standard
-smartmontools
-smartmontools-selinux


%end

%packages
# ^ keyword.control.packages.kickstart
openssh-server
%end

%packages
# ^ keyword.control.packages.kickstart
NetworkManager
%end
##### end package list ###############################################


##### begin kickstart post script ####################################
%post --erroronfail --log=/root/anaconda-post-1.log  # Script to configure system
# ^ keyword.control.script.kickstart
# ^ meta.section.script.kickstart
#       ^ script.argument.kickstart
#                                                     ^ comment.line.kickstart
# < source.bash

# Find the architecture we are on
arch=$(uname -m)

# Import RPM GPG key, during installation saved in /etc/pki
echo "Import RPM GPG key"
releasever=$(rpm --eval '%{fedora}')
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch

%end
##### end kickstart post script #####################################


##### begin custom post script (after base) #########################
%post --interpreter=/usr/bin/bash
# When we build the image /var/log gets populated.
# Let's clean it up.
echo "Cleanup leftover in /var/log"
cd /var/log  && find . -name \* -type f -delete
%end
##### end custom post script ########################################
# < -source.bash

%post --interpreter=/bin/bash/python # Comment
# ^ meta.section.script.kickstart
# ^ keyword.control.script.kickstart
#                                     ^ comment.line.kickstart
# < source.python
print("Kickstart is cool!")
%end

%pre --interpreter=python
print("Default python")
# < source.python
%end

%addon com_redhat_kdump --enable --reserve-mb=128
# ^ keyword.control.packages.kickstart
# ^ meta.section.addon.kickstart
#      ^ string.unquoted.addon.kickstart
#                        ^ meta.argument.kickstart
%end
