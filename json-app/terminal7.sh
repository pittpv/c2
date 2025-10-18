#!/bin/bash

# Script: terminal7.sh
# Description: Start Daml Sandbox with JSON API for capstone project
# Author: Canton Quest

set -e

# Configuration
LOG_FILE="../canton_quest.log"
PROJECT_DIR="capstone"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Wait for sandbox to be ready
wait_for_sandbox_ready() {
    log "Waiting for Canton Sandbox to become ready..."

    while true; do
        # Check for readiness message in the process output
        if tail -n 10 sandbox_output.log 2>/dev/null | grep -q "Canton sandbox is ready"; then
            log "✓ Canton Sandbox is ready!"
            return 0
        fi

        sleep 2
    done
}

# Cleanup function
cleanup() {
    log "Cleaning up..."

    if [ -n "$SANDBOX_PID" ] && kill -0 $SANDBOX_PID 2>/dev/null; then
        log "Stopping Canton Sandbox (PID: $SANDBOX_PID)..."
        kill $SANDBOX_PID
        sleep 2
        log "Canton Sandbox stopped"
    fi

    # Remove temporary log file
    rm -f sandbox_output.log
}

# Main execution function
main() {

    # Set trap for cleanup on script exit
    trap cleanup EXIT INT TERM

    # Check if project directory exists
    if [ ! -d "$PROJECT_DIR" ]; then
        error_exit "Project directory '$PROJECT_DIR' not found. Please run terminal6.sh first."
    fi

    # Change to project directory
    cd "$PROJECT_DIR"
    log "Changed to project directory: $(pwd)"

    log "Starting Daml Sandbox with JSON API on port 7575..."
    log "Command: daml sandbox --json-api-port 7575"

    # Start sandbox and capture output to temporary file
    daml sandbox --json-api-port 7575 > sandbox_output.log 2>&1 &
    SANDBOX_PID=$!

    log "Daml Sandbox started with PID: $SANDBOX_PID"

    # Wait for sandbox to be ready
    wait_for_sandbox_ready

    echo "================================================"
    echo "✅ Daml Sandbox is ready and running!"
    echo "📍 JSON API available on: localhost:7575"
    echo "📍 Sandbox ledger on: localhost:6865"
    echo ""
    echo "Press Ctrl+C to stop the sandbox."
    echo "================================================"

    # Wait for user interrupt (Ctrl+C)
    log "Sandbox is running. Waiting for Ctrl+C..."
    wait $SANDBOX_PID

    log "Terminal 7 execution completed"
}

# Run main function
main "$@"
