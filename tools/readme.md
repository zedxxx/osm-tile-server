Read this in other language: [Русский](readme.ru.md)

## Available commands

- `osm up`: Create and run a container with OSM Tile Server. The server must be initialized with the `osm import` command beforehand, so that the server has data for rendering.

- `osm down`: Stop and remove the OSM Tile Server container.

- `osm import [region-name]`: Import OSM data. If a region name is specified, its data will first be downloaded from geofabrik.de. If no region name is specified, the previously downloaded region is imported (from `/mnt/data/region.osm.pbf`). Examples of region names: `europe/belarus`, `russia/kaliningrad-oblast`, `russia`. This command completely removes the existing PostgreSQL database and Apache tile cache before importing.

- `osm get <region-name>`: Download the latest.osm.pbf and .poly of the region from geofabrik.de and save them to `/mnt/data/region.osm.pbf` and `/mnt/data/region.poly` files, respectively.

- `osm logs`: Show the logs of the running OSM Tile Server in real-time (follow).

- `osm render <lon,lat,LON,LAT,z,Z> [n]`: Start rendering tiles for a given geographic area (bbox), minimum and maximum zoom levels (z, Z), and number of threads (n). The bbox is specified in WGS84 geographic coordinates: lon, lat - lower left corner, LON, LAT - upper right corner. Zoom numbering starts from 1.

- `osm pg <subcommand>`: Manage PostgreSQL in the OSM Tile Server container.
  - `run`: Create and run a container with the PostgreSQL server.
  - `stop`: Stop the running container with the PostgreSQL server.
  - `analyze`: Execute the `ANALYZE` command in the database.
  - `vacuum`: Execute the `VACUUM` command in the database.
  - `convert`: Execute the `convert-names.sql` script to change map language.
  