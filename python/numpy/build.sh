#!/usr/bin/env bash
set -e
SCRIPT_PATH=$(dirname $(readlink -f $0))


echo "==================================="
echo "  Building docker"
echo "==================================="
docker build -t temp_alpine_numpy $SCRIPT_PATH


echo
echo "==================================="
echo "  Flattening image"
echo "==================================="
container_id=$(docker run -d temp_alpine_numpy sh -c "while true; do sleep 1; done")
docker export $container_id | docker import - alpine_numpy:latest
docker kill $container_id
docker rm -f $container_id
docker rmi -f temp_alpine_numpy

echo
echo "==================================="
echo "  Built image"
echo "==================================="
docker images | grep alpine_numpy:airflow-test