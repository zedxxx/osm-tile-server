## Quick Start

1. Install [VMware Workstation Pro](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion) or [VirtualBox](https://www.virtualbox.org/)
2. Download the pre-configured virtual machine [osm-tile-server-vm.zip]()
3. Extract it to a drive with sufficient capacity, preferably an SSD
4. Launch VMware/VirtualBox, open the extracted virtual machine and power it on
5. After boot completes, log in as *root* with password *alpine*
6. Import a small test region (Europe, Luxembourg) using command `osm import europe/luxembourg)`
7. After import completes, start the server: `osm up`
8. Open browser at `http://<your-vm-ip-address>/`
9. Verify that the map displays properly
10. Import your desired region: `osm import <your-region-name>`

Notes:

- You can find the machine's IP address with command `ifconfig eth0`
- On first region import, approximately 2 GB of data will be downloaded from the internet (docker image, region's latest.osm.pbf file, external data with country and sea boundaries). On subsequent imports only the region file will be downloaded. When running the import command without specifying a region name (`osm import`), cached data will be imported without initial download. If country and sea boundaries are not needed, change `/mnt/data/cache` to `/mnt/data/cache-empty` in `docker-compose.yml` - this will save several minutes during import
- Regions are downloaded from [download.geofabrik.de](https://download.geofabrik.de/). You can find the exact region name from the URL of your desired region
- Only one region can be imported; each subsequent import removes results of the previous one
- If you need to import two or more regions, they must be merged into one. Use the [osmium](https://osmcode.org/osmium-tool/) utility for this (Windows 64-bit version [here]()). The merged file should be copied to `/mnt/data/region.osm.pbf` (the `region.poly` file with region boundaries is optional)
- To access the virtual machine via SSH, use [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/), for FTP and SFTP use [WinSCP](https://winscp.net/eng/downloads.php). A portable "all-in-one" package can be found [here]().

## Additional Information

Repository structure:

- `image` - scripts and Docker file for building the docker image. The ready image is available at [DockerHub](https://hub.docker.com/r/zed43/osm-tile-server)
- `tools` - scripts that facilitate interaction with the OSM server. Available commands are described in [tools/readme.md]()
- `vm` - script and instructions for setting up a virtual machine "from scratch"
- `docker-compose.yml` - configuration for creating and running the docker container