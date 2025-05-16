#!/bin/bash

# Function to display status messages
display_status() {
    osascript -e "display notification \"$1\" with title \"Kill Zscaler\""
}

# Function to check if Zscaler is running
check_zscaler() {
    pgrep -i "zscaler" > /dev/null
    return $?
}

# Function to kill Zscaler processes
kill_zscaler_processes() {
    pkill -i "zscaler" 2>/dev/null
}

# Main execution
if ! check_zscaler; then
    display_status "Zscaler is not running"
    exit 0
fi

# Unload LaunchDaemons (requires admin privileges)
if /usr/bin/osascript -e 'do shell script "find /Library/LaunchDaemons -name *zscaler* -exec launchctl unload {} \\;" with administrator privileges'; then
    display_status "Successfully unloaded Zscaler system services"
else
    display_status "Failed to unload some Zscaler system services"
fi

# Unload LaunchAgents (user context)
if /usr/bin/osascript -e 'do shell script "find /Library/LaunchAgents -name *zscaler* -exec launchctl unload {} \\;"'; then
    display_status "Successfully unloaded Zscaler user services"
else
    display_status "Failed to unload some Zscaler user services"
fi

# Kill any remaining Zscaler processes
kill_zscaler_processes

# Final check
if check_zscaler; then
    display_status "Warning: Some Zscaler processes may still be running"
else
    display_status "Successfully stopped Zscaler"
fi
