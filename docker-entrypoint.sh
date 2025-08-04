#!/bin/bash
set -e

export APP=${APP:-go-http-server-template}

log() {
  local date status message
  date=$(date -u +%Y-%m-%dT%H:%M:%S%z)
  status="$1"
  shift
  message=$(echo "$@" | sed s/$/\\n/g)
  printf '{"time":"%s","status":"%s","message":"%s"}\n' "$date" "$status" "$message"
}

# We need to know if flavor is set
if [ -n "${FLAVOR+x}" ]; then
  log INFO "Starting APP=${APP} with FLAVOR=${FLAVOR}"
else
  log WARN "WARNING: No FLAVOR, environment may not load properly."
fi

if [ "${CHAMBER_ENABLED:-true}" = "false" ]; then
  log INFO "CHAMBER_ENABLED is \"${CHAMBER_ENABLED}\" so skipping attempt to load environment via chamber"
else
  chamber_environments="global $FLAVOR $APP ${FLAVOR:+$APP-$FLAVOR}"
  log INFO "Attempting to load environment variables from SSM parameter store via chamber for: ${chamber_environments}"

  # If FLAVOR=dev then: chamber exec global dev $APP $APP-dev
  # If FLAVOR is not set or is empty, then: chamber exec global $APP
  chamber -r 3 exec $chamber_environments -- sh -c 'export -p' > /tmp/env 2> /tmp/chamber-stderr || {
    log ERROR "$(cat /tmp/chamber-stderr)"
    log ERROR "chamber failed, exiting"
    rm -f /tmp/env /tmp/chamber-stderr
    exit 1
  }
  . /tmp/env
  rm -f /tmp/env /tmp/chamber-stderr
fi

if [[ $1 =~ ^(/bin/)?(ba)?sh$ ]]; then
  log INFO "First CMD argument is a shell: $1"
  log INFO "Running: exec $@"
  exec "$@"
elif [[ "$*" =~ ([;<>]|\(|\)|\&\&|\|\|) ]]; then
  log INFO "Shell metacharacters detected, passing CMD to bash"
  _quoted="$*"
  log INFO "Running: exec /bin/bash -c ${_quoted@Q}"
  unset _quoted
  exec /bin/bash -c "$*"
fi

# Use dumb-init to ensure proper handling of signals, zombies, etc.
# See https://github.com/Yelp/dumb-init
log INFO "Running command: /usr/bin/dumb-init $@"
exec /usr/bin/dumb-init "$@"
