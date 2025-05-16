#!/bin/bash

# Zscaler Control Script
# Version: 1.0.0
# Description: Controls Zscaler VPN service on macOS with error handling and logging

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

# Check if Zscaler is installed
check_zscaler_installed() {
    if [ ! -d "$ZSCALER_APP" ]; then
        log "ERROR" "Zscaler not installed at $ZSCALER_APP"
        notify "Zscaler Error" "Zscaler is not installed"
        exit 1
    fi
}

# System notification function
notify() {
    local title="$1"
    local message="$2"
    osascript -e "display notification \"$message\" with title \"$title\""
}

# Start Zscaler application
start_zscaler_app() {
    log "INFO" "Starting Zscaler application..."
    if ! open -a "$ZSCALER_APP" --hide; then
        log "ERROR" "Failed to start Zscaler application"
        return 1
    fi
    return 0
}

# Load Zscaler launch daemons
load_launch_daemons() {
    local retry_count=0
    log "INFO" "Loading Zscaler launch daemons..."
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if sudo find /Library/LaunchDaemons -name "*zscaler*" -exec launchctl load {} \; 2>/dev/null; then
            log "INFO" "Successfully loaded Zscaler launch daemons"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        log "WARNING" "Failed to load launch daemons (attempt $retry_count/$MAX_RETRIES)"
        sleep $RETRY_DELAY
    done
    
    log "ERROR" "Failed to load Zscaler launch daemons after $MAX_RETRIES attempts"
    return 1
}

# Check Zscaler status
check_status() {
    local running=0
    
    # Check if main process is running
    if pgrep -f "Zscaler.app" >/dev/null; then
        running=1
    fi
    
    # Check if daemons are loaded
    if launchctl list | grep -q "zscaler"; then
        running=$((running + 1))
    fi
    
    case $running in
        0) log "INFO" "Zscaler status: Not running" ;;
        1) log "WARNING" "Zscaler status: Partially running" ;;
        2) log "INFO" "Zscaler status: Fully running" ;;
    esac
    
    return $running
}

# Main function
main() {
    log "INFO" "=== Starting Zscaler services ==="
    
    check_privileges
    check_zscaler_installed
    
    if ! start_zscaler_app; then
        notify "Zscaler Error" "Failed to start Zscaler application"
        exit 1
    fi
    
    if ! load_launch_daemons; then
        notify "Zscaler Error" "Failed to load Zscaler services"
        exit 1
    fi
    
    # Final status check
    sleep 2  # Give services time to start
    check_status
    status=$?
    
    if [ $status -eq 2 ]; then
        notify "Zscaler" "Zscaler services started successfully"
        log "INFO" "Zscaler startup completed successfully"
    else
        notify "Zscaler Warning" "Zscaler may not be fully operational"
        log "WARNING" "Zscaler startup completed with warnings"
    fi
}

main
