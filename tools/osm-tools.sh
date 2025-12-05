#!/bin/bash

set -euo pipefail

compose_dir=/osm
tools_dir=/osm/tools
data_dir=/mnt/data

function usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
  up                Create and run container with OSM Tile Server
  down              Stop and delete OSM Tile Server container
  import [region]   Import OSM data (optionally download region first)
  get <region>      Download region data (examples: europe/belarus, russia/kaliningrad, russia)
  logs              Show OSM Tile Server logs (follow mode)
  render [bbox,z,Z] Run tile rendering for the given wgs84 bbox and min, max zooms (count from 1)
  pg <subcommand>   Manage PostgreSQL in the OSM Tile Server container:
                      run          Create and run container with PostgreSQL server
                      stop         Stop running container with PostgreSQL server
                      analyze      Run ANALYZE
                      vacuum       Run VACUUM
                      vacuum-full  Run VACUUM FULL
                      convert      Execute convert-names.sql
EOF
}

if [ "$#" -eq 0 ]; then
    usage
    exit 1
fi

if [ "$1" == "up" ]; then
    cd "${compose_dir}"
    docker compose up --detach
    exit 0
fi

if [ "$1" == "down" ]; then
    cd "${compose_dir}"
    docker compose down
    exit 0
fi

function download_region() {
    local region="$1"
    local url="https://download.geofabrik.de/${region}"
    
    rm -fv "${data_dir}/region.osm.pbf" "${data_dir}/region.poly"

    echo "Downloading region data..."
    
    wget -O "${data_dir}/region.osm.pbf" "${url}-latest.osm.pbf"
    if ! wget -O "${data_dir}/region.poly" "${url}.poly"; then
        echo "No .poly file found for ${region}, continuing without it..."
    fi
}

if [ "$1" == "import" ]; then
    
    if [ -n "${2:-}" ]; then
        download_region "$2"
    fi

    cd "${compose_dir}"

    docker compose down
   
    rm -rf "${data_dir}/database"
    rm -rf "${data_dir}/tiles"

    time docker compose run --rm --name osm-import osm import

    exit 0
fi

if [ "$1" == "get" ]; then
    if [ -n "${2:-}" ]; then
        download_region "$2"
        exit 0
    else
        echo "Provide region name! Examples: europe/belarus, russia/kaliningrad, russia"
        exit 1
    fi
fi

if [ "$1" == "logs" ]; then
    cd "${compose_dir}"
    exec docker compose logs --follow
fi

function run_render_list_geo() {
    local x y X Y z Z
    IFS=',' read -r x y X Y z Z <<< "$1"
    z=$((z-1))
    Z=$((Z-1))
    local render_geo=render-list-geo.pl
    docker cp "${tools_dir}/${render_geo}" "osm:/${render_geo}"
    time docker exec -it osm "/${render_geo}" -n "$2" -x "$x" -y "$y" -X "$X" -Y "$Y" -z "$z" -Z "$Z"
}

if [ "$1" == "render" ]; then
    run_render_list_geo "$2" "${3:-1}"
    exit 0
fi

# PostgreSQL

pg_db_name=gis
pg_user_name=postgres
pg_container_name=osm-pg

function pg_check_running() {
    docker ps --filter "name=${pg_container_name}" --filter "status=running" | grep -q "${pg_container_name}"
}

function pg_run_psql() {
    local sql="$1"
    time docker exec -it "${pg_container_name}" psql -h localhost -U "${pg_user_name}" -d "${pg_db_name}" -c "${sql}"
}

function pg_run_convert() {
    docker cp "${tools_dir}/convert-names.sql" "${pg_container_name}:/convert.sql"
    time docker exec -it "${pg_container_name}" psql -h localhost -U "${pg_user_name}" -d "${pg_db_name}" -f /convert.sql
}

function pg_error_not_running() {
    echo "${pg_container_name} container isn't running!"
    echo "Type \"osm pg run\" to run container"
    exit 1
}

if [ "$1" == "pg" ]; then

    case "${2:-run}" in
    "run")
        cd "${compose_dir}"
        docker compose run --rm --name "${pg_container_name}" osm run-pg
        exit 0
        ;;

    "stop")
        docker stop "${pg_container_name}"
        exit 0
        ;;

    "analyze")
        if pg_check_running; then
            pg_run_psql "ANALYZE;"
            exit 0
        else
            pg_error_not_running
        fi
        ;;
        
    "vacuum")
        if pg_check_running; then
            pg_run_psql "VACUUM;"
            exit 0
        else
            pg_error_not_running
        fi
        ;;
    
    "vacuum-full")
        if pg_check_running; then
            pg_run_psql "VACUUM FULL;"
            exit 0
        else
            pg_error_not_running
        fi
        ;;
    
    "convert")
        if pg_check_running; then
            pg_run_convert            
            exit 0
        else
            pg_error_not_running
        fi
        ;;
    
    *)
        echo "Usage: $0 pg <run|stop|analyze|vacuum|vacuum-full|convert>"
        exit 1
        ;;
    esac
fi
