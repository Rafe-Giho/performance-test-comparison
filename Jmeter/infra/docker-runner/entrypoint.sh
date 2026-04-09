#!/usr/bin/env sh
set -eu

PLAN_PATH="${PLAN_PATH:-/workspace/plans/web-standard-template.jmx}"
REPORT_BASE="${REPORT_BASE:-/workspace/reports/container-runner}"
RESULT_PREFIX="${RESULT_PREFIX:-jmeter}"

mkdir -p "${REPORT_BASE}"

timestamp="$(date +%Y%m%d-%H%M%S)"
result_file="${REPORT_BASE}/${RESULT_PREFIX}-${timestamp}.jtl"
html_dir="${REPORT_BASE}/${RESULT_PREFIX}-html-${timestamp}"

jmeter -n \
  -t "${PLAN_PATH}" \
  -l "${result_file}" \
  -e \
  -o "${html_dir}" \
  -JPROTOCOL="${PROTOCOL:-https}" \
  -JHOST="${HOST:-example.com}" \
  -JPORT="${PORT:-443}" \
  -JTHREADS="${THREADS:-10}" \
  -JRAMP_UP="${RAMP_UP:-30}" \
  -JLOOPS="${LOOPS:-1}" \
  -JTHINK_TIME_MS="${THINK_TIME_MS:-1000}" \
  -JUSERNAME="${USERNAME:-user01}" \
  -JPASSWORD="${PASSWORD:-pass01}"

echo "JTL=${result_file}"
echo "HTML=${html_dir}"
