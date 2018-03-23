#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
YELLOW_BOLD='\033[1;33m'
NO_COLOR='\033[0m'

print_usage() {
	echo -e "${YELLOW_BOLD}Usage:${YELLOW} docker run -it --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v reports:/tmp/reports pipedrive/container-performance-analyzer <target container id> [ <montoring time in seconds> ] ${NO_COLOR}\n"
}

error() {
	echo -e "${RED}ERROR:${NO_COLOR} ${1} ${NO_COLOR}\n"
}

usage_error() {
	error "${1}"
	print_usage
	exit 1
}

if [ ! -e /var/run/docker.sock ]; then
	usage_error "Docker socket file not found, use ${YELLOW}-v /var/run/docker.sock:/var/run/docker.sock"
fi

if [ ! -w /tmp/reports ]; then
	usage_error "/tmp/reports doesn't exist or is not readable, use ${YELLOW}-v reports:/tmp/reports"
fi

if [ -z "${1}" ]; then
	usage_error "target container id is not set"
fi

PROCESS_PATTERN="${PROCESS_PATTERN-[n]ode}"
TARGET_CONTAINER_ID=${1}
MONITORING_TIME=${2:-10}
REPORT_ID=${REPORT_ID:-$(date +%s)}
PROCESS_IDS=$(ps -A -o pid,command | awk '/'"$PROCESS_PATTERN"'/ { print $1 }')

if [ -z "${PROCESS_IDS}" ]; then
	error "no ${PROCESS_PATTERN} processes found in the target container, exiting.."
	exit 1
fi

REPORTS_DIR="/tmp/reports/report.${REPORT_ID}"
mkdir -p "${REPORTS_DIR}"

for pid in ${PROCESS_IDS}; do
	perf_data_file="${REPORTS_DIR}/stacks.${pid}.data"
	echo "writing monitoring data for pid ${pid} to ${perf_data_file}"
	perf record -e cpu-clock -F 30 -g -p "${pid}" -o "${perf_data_file}" -- sleep ${MONITORING_TIME}&
done
sleep $((MONITORING_TIME + 5))

mkdir /tmp/map-files
docker cp "${TARGET_CONTAINER_ID}:/tmp/" /tmp/map-files
chown -R "$(id -u):$(id -g)" /tmp/map-files
find /tmp/map-files -name "*.map" -exec cp {} /tmp \;

for pid in ${PROCESS_IDS}; do
	perf_data_file="${REPORTS_DIR}/stacks.${pid}.data"
	perf_report_file="${REPORTS_DIR}/stacks.${pid}.out"

	perf script -f -i "${perf_data_file}" > "${perf_report_file}"
	rm -f "${perf_data_file}"
done

0x --visualize-only "${REPORTS_DIR}" || echo "failed to generate flame HTML"