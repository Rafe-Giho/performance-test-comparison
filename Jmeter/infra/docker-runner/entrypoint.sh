#!/usr/bin/env sh
set -eu

PLAN_PATH="${PLAN_PATH:-/workspace/plans/web-standard-template.jmx}"
RESULT_PREFIX="${RESULT_PREFIX:-jmeter}"

require_env() {
  name="$1"
  eval "value=\${$name:-}"
  if [ -z "$value" ]; then
    echo "Required environment variable is not set: $name" >&2
    exit 2
  fi
}

for name in PROJECT_NAME PROTOCOL HOST PORT THREADS RAMP_UP LOOPS THINK_TIME_MS HEALTH_PATH LOGIN_PATH LIST_PATH DETAIL_PATH EVENT_PATH EVENT_PAYLOAD USERNAME PASSWORD; do
  require_env "$name"
done

REPORT_BASE="${REPORT_BASE:-/workspace/reports/${PROJECT_NAME}/$(date +%Y%m%d)}"

mkdir -p "${REPORT_BASE}"

timestamp="$(date +%Y%m%d-%H%M%S)"
result_file="${REPORT_BASE}/${RESULT_PREFIX}-${timestamp}.jtl"
html_dir="${REPORT_BASE}/${RESULT_PREFIX}-html-${timestamp}"

jmeter -n \
  -t "${PLAN_PATH}" \
  -l "${result_file}" \
  -e \
  -o "${html_dir}" \
  -JPROTOCOL="${PROTOCOL}" \
  -JHOST="${HOST}" \
  -JPORT="${PORT}" \
  -JTHREADS="${THREADS}" \
  -JRAMP_UP="${RAMP_UP}" \
  -JLOOPS="${LOOPS}" \
  -JTHINK_TIME_MS="${THINK_TIME_MS}" \
  -JHEALTH_PATH="${HEALTH_PATH}" \
  -JLOGIN_PATH="${LOGIN_PATH}" \
  -JLIST_PATH="${LIST_PATH}" \
  -JDETAIL_PATH="${DETAIL_PATH}" \
  -JUSERNAME="${USERNAME}" \
  -JPASSWORD="${PASSWORD}" \
  -JEVENT_PATH="${EVENT_PATH}" \
  -JEVENT_PAYLOAD="${EVENT_PAYLOAD}"

echo "JTL=${result_file}"
echo "HTML=${html_dir}"
