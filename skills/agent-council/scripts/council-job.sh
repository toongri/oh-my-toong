#!/bin/bash
#
# council-job.sh - Wrapper for council-job.js
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOB_JS="$SCRIPT_DIR/council-job.js"

exec node "$JOB_JS" "$@"
