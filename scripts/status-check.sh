#!/bin/bash

# Source configuration
source "$(dirname "$0")/config.sh"

# Check if main process is running
if pgrep -f "Zscaler.app" >/dev/null; then
    process_running=true
else
    process_running=false
fi

# Check if daemons are loaded
if launchctl list | grep -q "zscaler"; then
    daemons_loaded=true
else
    daemons_loaded=false
fi

# Determine status
if $process_running && $daemons_loaded; then
    echo "Fully running"
elif $process_running || $daemons_loaded; then
    echo "Partially running"
else
    echo "Not running"
fi

exit 0
