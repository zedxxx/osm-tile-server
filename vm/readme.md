## Install VMware virtual machine

1. Download and install [VMWare Workstation Pro](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion)
2. Create new virtual machine: Linux - Other Linux 6.x kernel 64-bit
3. Hardware:
   1. CPU: 8 cores (4 processors with 2 cores per processor), Enable all 3 options under Virtualization Engine
   2. RAM: 16 GB
   3. HDD: 1 GB (system)
   4. Network: Bridged
4. Edit VM settings:
   1. Add second HDD: 1000 GB (data)
   2. (Optional) Add third HDD: 16 GB (swap)

*When you create virtual disks always select "Store virtual disk as a single file".*

## Install Alpine Linux

1. Download [ISO image](https://alpinelinux.org/downloads/) Virtual edition (x86_64 version)
2. Login: root (when you boot from iso a password isn't required)
3. Install: `SWAP_SIZE=0 setup-alpine` (without swap)
4. All by default, except:
    1. Keymap: us us
    2. Root Password: alpine
    3. Apk Mirror: c (enable community repository)
    4. User - Allow root ssh login: yes (enable ssh and sftp login by password for root)
    5. Disk & Install: sda sys
5. (Optional) If you don't have enough RAM you can use third HDD for [swap](https://wiki.alpinelinux.org/wiki/Swap)

## Format and Mount second HDD

1. Connect to the VM via SSH using [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/). You can find the machine's IP address with command `ifconfig eth0`
2. Run `fdisk -l` to get the disk name (usually it should be `/dev/sdb`)
3. Create new primary partition on drive sdb:
   1. `fdisk /dev/sdb`
   2. `n` - create new partition
   3. `p` - primary
   4. `1` - number
   5. `w` - write changes
4. Format: `mkfs.ext4 /dev/sdb1`
5. Create mount point: `mkdir -p /mnt/data`
6. Automount on boot: `echo "UUID=$(blkid -s UUID -o value /dev/sdb1)  /mnt/data  ext4  defaults  0  2" >> /etc/fstab`
7. Test it: `mount -a`

## Setup Alpine Linux

1. Connect to the VM via SSH.
2. Create `fetch` script:

```bash
cat > fetch.sh << EOL
#!/bin/sh
set -euox pipefail
wget -O master.zip https://github.com/zedxxx/osm-tile-server/archive/refs/heads/master.zip
unzip -o master.zip && rm -fv master.zip
rm -rfv /osm/
mv -fv ./osm-tile-server-master/ /osm/
chmod a+x /osm/vm/alpine-setup.sh
chmod a+x /osm/tools/osm-tools.sh
chmod a+x /osm/tools/render-list-geo.pl
EOL
```

3. Run `fetch` script: `chmod +x ./fetch.sh && ./fetch.sh`
4. Run `alpine-setup` script: `/osm/vm/alpine-setup.sh` 
