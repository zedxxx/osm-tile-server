#!/bin/bash

set -euox pipefail

WORK_DIR=/osm
DATA_DIR=/mnt/data

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
    cd "${WORK_DIR}"
    docker compose up --detach
    exit 0
fi

if [ "$1" == "down" ]; then
    cd "${WORK_DIR}"
    docker compose down
    exit 0
fi

function download_region() {
    local REGION="$1"
    rm -fv "${DATA_DIR}/region.osm.pbf" "${DATA_DIR}/region.poly"
    URL="https://download.geofabrik.de/${REGION}"
    echo "Downloading region data..."
    wget -O "${DATA_DIR}/region.osm.pbf" "${URL}-latest.osm.pbf"
    if ! wget -O "${DATA_DIR}/region.poly" "${URL}.poly"; then
        echo "No .poly file found for ${REGION}, continuing without it..."
    fi
}

if [ "$1" == "import" ]; then
    
    if [ -n "${2:-}" ]; then
        download_region "$2"
    fi

    cd "${WORK_DIR}"

    docker compose down
   
    rm -rf "${DATA_DIR}/database"
    rm -rf "${DATA_DIR}/tiles"

    time docker compose run --rm --name osm-import osm import

    exit 0
fi

if [ "$1" == "get" ]; then
    cd "${WORK_DIR}"
    if [ -n "${2:-}" ]; then
        download_region "$2"
        exit 0
    else
        echo "Provide region name! Examples: europe/belarus, russia/kaliningrad, russia"
        exit 1
    fi
fi

if [ "$1" == "logs" ]; then
    cd "${WORK_DIR}"
    exec docker compose logs --follow
fi

function run_render_list_geo() {
    local x y X Y z Z
    IFS=',' read -r x y X Y z Z <<< "$1"
    z=$((z-1))
    Z=$((Z-1))
    local render_geo=render-list-geo.pl
    docker cp "./${render_geo}" "osm:/${render_geo}"
    time docker exec -it osm "${render_geo}" -x "$x" -y "$y" -X "$X" -Y "$Y" -z "$z" -Z "$Z"
}

if [ "$1" == "render" ]; then
    cd "${WORK_DIR}"
    run_render_list_geo "$2"
    exit 0
fi

# PostgreSQL

PG_DB=gis
PG_USER=postgis
PG_CONTAINER_NAME=osm-pg

function pg_check_running() {
    docker ps --filter "name=${PG_CONTAINER_NAME}" --filter "status=running" | grep -q "${PG_CONTAINER_NAME}"
}

function pg_run_psql() {
    local sql="$1"
    time docker exec -it "${PG_CONTAINER_NAME}" psql -h localhost -U "${PG_USER}" -d "${PG_DB}" -c "${sql}"
}

function pg_run_convert() {
    docker cp ./convert-names.sql "${PG_CONTAINER_NAME}:/convert.sql"
    time docker exec -it "${PG_CONTAINER_NAME}" psql -h localhost -U "${PG_USER}" -d "${PG_DB}" -f /convert.sql
}

function pg_error_not_running() {
    echo "${PG_CONTAINER_NAME} container isn't running!"
    echo "Type \"osm pg run\" to run container"
    exit 1
}

if [ "$1" == "pg" ]; then
    
    cd "${WORK_DIR}"

    case "${2:-}" in
    "run")
        docker compose run --rm --name "${PG_CONTAINER_NAME}" osm run-pg
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
        echo "Usage: $0 pg <run|analyze|vacuum|vacuum-full|convert>"
        exit 1
        ;;
    esac
fi
