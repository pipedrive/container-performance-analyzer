#!/usr/bin/env bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
YELLOW_BOLD='\033[1;33m'
NO_COLOR='\033[0m'

if [ -z "$1" ]; then
	echo -e "${YELLOW_BOLD}Usage:${YELLOW}$0 <container id> [ <monitoring time> ]${NO_COLOR}"
	exit 1
fi


CONTAINER_ID=${1}
REPORTS_DIR="$(pwd)/reports"
mkdir -p "${REPORTS_DIR}"

docker run --rm -it --privileged --pid="container:${CONTAINER_ID}" -v /var/run/docker.sock:/var/run/docker.sock -v ${REPORTS_DIR}:/tmp/reports pipedrive/container-performance-analyzer "$@"
