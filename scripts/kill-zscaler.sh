#!/bin/bash

# Zscaler Control Script
# Version: 1.0.0
# Description: Stops Zscaler VPN service on macOS with error handling and logging

# Configuration
ZSCALER_APP="/Applications/Zscaler/Zscaler.app"
LOG_DIR="$HOME/.zscaler"
LOG_FILE="$LOG_DIR/zscaler-control.log"
MAX_RETRIES=3
RETRY_DELAY=2

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] - $message" >> "$LOG_FILE"
    
    # For errors, also print to stderr
    if [ "$level" = "ERROR" ]; then
        echo "Error: $message" >&2
    fi
}

# Check if running with necessary privileges
check_privileges() {
    if [ "$(id -u)" != "0" ] && ! sudo -n true 2>/dev/null; then
        log "WARNING" "Some operations may require administrative privileges"
    fi
}

# System notification function
notify() {
    local title="$1"
    local message="$2"
    osascript -e "display notification \"$message\" with title \"$title\""
}

# Unload Zscaler launch agents
unload_launch_agents() {
    log "INFO" "Unloading Zscaler launch agents..."
    local agents_found=false
    
    while read -r agent; do
        agents_found=true
        if launchctl unload "$agent" 2>/dev/null; then
            log "INFO" "Unloaded agent: $agent"
        else
            log "WARNING" "Failed to unload agent: $agent"
        fi
    done < <(find /Library/LaunchAgents -name '*zscaler*' 2>/dev/null)
    
    if ! $agents_found; then
        log "INFO" "No Zscaler launch agents found"
    fi
}

# Unload Zscaler launch daemons
unload_launch_daemons() {
    log "INFO" "Unloading Zscaler launch daemons..."
    local retry_count=0
    local success=false
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if sudo find /Library/LaunchDaemons -name '*zscaler*' -exec launchctl unload {} \; 2>/dev/null; then
            log "INFO" "Successfully unloaded Zscaler launch daemons"
            success=true
            break
        fi
        
        retry_count=$((retry_count + 1))
        log "WARNING" "Failed to unload launch daemons (attempt $retry_count/$MAX_RETRIES)"
        sleep $RETRY_DELAY
    done
    
    if ! $success; then
        log "ERROR" "Failed to unload Zscaler launch daemons after $MAX_RETRIES attempts"
        return 1
    fi
    return 0
}

# Kill Zscaler processes
kill_zscaler_processes() {
    log "INFO" "Terminating Zscaler processes..."
    
    # List of common Zscaler process patterns
    local patterns=("Zscaler.app" "ZscalerService" "ZscalerTunnel")
    
    for pattern in "${patterns[@]}"; do
        local pids=$(pgrep -f "$pattern")
        if [ -n "$pids" ]; then
            log "INFO" "Found $pattern processes: $pids"
            if ! kill $pids 2>/dev/null; then
                log "WARNING" "Failed to terminate some $pattern processes"
                # Try force kill if regular kill failed
                kill -9 $pids 2>/dev/null
            fi
        fi
    done
}

# Check if Zscaler is completely stopped
verify_stopped() {
    local running_processes=$(pgrep -f "Zscaler")
    if [ -n "$running_processes" ]; then
        log "WARNING" "Some Zscaler processes are still running"
        return 1
    fi
    
    if launchctl list | grep -q "zscaler"; then
        log "WARNING" "Some Zscaler services are still loaded"
        return 1
    fi
    
    log "INFO" "Verified Zscaler is completely stopped"
    return 0
}

# Main function
main() {
    log "INFO" "=== Stopping Zscaler services ==="
    
    check_privileges
    
    unload_launch_agents
    if ! unload_launch_daemons; then
        notify "Zscaler Error" "Failed to unload some Zscaler services"
        exit 1
    fi
    
    kill_zscaler_processes
    
    # Final verification
    sleep 2  # Give processes time to stop
    if verify_stopped; then
        notify "Zscaler" "Zscaler services stopped successfully"
        log "INFO" "Zscaler shutdown completed successfully"
    else
        notify "Zscaler Warning" "Some Zscaler components may still be running"
        log "WARNING" "Zscaler shutdown completed with warnings"
    fi
}

main
