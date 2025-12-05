#!/bin/sh

set -euox pipefail

osm_dir=/osm
data_dir=/mnt/data

# Base tools
apk add bash make mc nano htop

# VMware tools https://wiki.alpinelinux.org/wiki/Open-vm-tools
apk add open-vm-tools open-vm-tools-guestinfo open-vm-tools-deploypkg

rc-service open-vm-tools start
rc-update add open-vm-tools boot

# FTP server
apk add vsftpd

cat > /etc/vsftpd/vsftpd.conf << EOF
listen=YES
local_root=/
local_enable=YES
write_enable=YES
chroot_local_user=NO
anonymous_enable=NO
seccomp_sandbox=NO
EOF

rc-service vsftpd start
rc-update add vsftpd

netstat -npl

# Docker https://wiki.alpinelinux.org/wiki/Docker
apk add docker docker-compose

mkdir --parents /etc/docker

cat > /etc/docker/daemon.json << EOF
{
    "data-root": "${data_dir}/docker"
}
EOF

rc-service docker start
rc-update add docker

docker info

# Disable autostart not-necessary services
#rc-update del ntpd || true
#rc-update del sshd || true
#rc-update del vsftpd || true
#rc-update del loadkmap boot || true

# Setup tools script
chmod a+x "${osm_dir}/tools/render-list-geo.pl"
chmod a+x "${osm_dir}/tools/osm-tools.sh"
ln -sfTv "${osm_dir}/tools/osm-tools.sh" /usr/local/bin/osm

# External data (empty)
unzip -o "${osm_dir}/vm/external-data-empty.zip" -d "${data_dir}"
rm -rfv "${data_dir}/cache-empty"
mv -fv "${data_dir}/external-data-empty" "${data_dir}/cache-empty"

# Clean up
apk cache clean
rm -rfv /var/logs/*
