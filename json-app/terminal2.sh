#!/bin/bash

# Script: terminal2.sh
# Description: Start Canton Sandbox and JSON API
# Author: Canton Quest

set -e

# Configuration
LOG_FILE="../canton_quest.log"
PROJECT_DIR="json-tests"
PID_DIR="$PROJECT_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check if processes are already running
check_existing_processes() {
    if [ -f "$PID_DIR/sandbox.pid" ] && kill -0 $(cat "$PID_DIR/sandbox.pid") 2>/dev/null; then
        log "Canton Sandbox is already running with PID: $(cat "$PID_DIR/sandbox.pid")"
        return 0
    fi

    if [ -f "$PID_DIR/json_api.pid" ] && kill -0 $(cat "$PID_DIR/json_api.pid") 2>/dev/null; then
        log "JSON API is already running with PID: $(cat "$PID_DIR/json_api.pid")"
        return 0
    fi

    return 1
}

# Apply bash configuration
apply_bash_config() {
    log "Applying bash configuration..."
    source "$HOME/.bashrc"
    log "Bash configuration applied"
}

# Start Canton Sandbox
start_canton_sandbox() {
    log "Starting Canton Sandbox..."

    if [ ! -d "$PROJECT_DIR" ]; then
        error_exit "Project directory $PROJECT_DIR not found"
    fi

    cd "$PROJECT_DIR"

    local dar_file=$(find .daml/dist -name "json-tests-*.dar" | head -1)

    if [ -z "$dar_file" ]; then
        error_exit "DAML archive file not found"
    fi

    log "Using DAR file: $dar_file"

    # Start sandbox in background and capture PID
    daml sandbox --wall-clock-time --dar "$dar_file" >> "../$LOG_FILE" 2>&1 &
    SANDBOX_PID=$!
    echo "$SANDBOX_PID" > sandbox.pid

    log "Canton Sandbox started with PID: $SANDBOX_PID"

    # Wait a moment for sandbox to initialize and check if it's still running
    sleep 5

    if ! kill -0 $SANDBOX_PID 2>/dev/null; then
        error_exit "Canton Sandbox process died immediately after start. Check $LOG_FILE for details."
    fi

    log "Canton Sandbox is running successfully"
    cd ..
}

# Create JSON API configuration
create_json_api_config() {
    log "Creating JSON API configuration..."

    cd "$PROJECT_DIR"

    cat > json-api-app.conf << 'EOF'
{
  server {
    address = "localhost"
    port = 7575
  }
  ledger-api {
    address = "localhost"
    port = 6865
  }
}
EOF

    log "JSON API configuration file created: json-api-app.conf"
    cd ..
}

# Wait for JSON API to be ready (non-fatal version)
wait_for_json_api_ready() {
    log "Waiting for JSON API to become ready..."

    local max_retries=30
    local retry_count=0
    local wait_seconds=2

    while [ $retry_count -lt $max_retries ]; do
        # Check if process is still running
        if ! kill -0 $JSON_API_PID 2>/dev/null; then
            log "WARNING: JSON API process died unexpectedly. Check $LOG_FILE for details."
            return 1
        fi

        # Check log for readiness message
        if tail -n 50 "../$LOG_FILE" | grep -q "Canton sandbox is ready"; then
            log "JSON API is ready - Canton sandbox is ready"
            return 0
        fi

        # Alternative check: try to connect to the API endpoint
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:7575/health 2>/dev/null | grep -q "200"; then
            log "JSON API is ready - Health endpoint responding"
            return 0
        fi

        # Check readyz endpoint specifically
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:7575/readyz 2>/dev/null | grep -q "200"; then
            log "JSON API is ready - Readyz endpoint responding"
            return 0
        fi

        # Another alternative: check if port is listening
        if netstat -tuln 2>/dev/null | grep -q ":7575.*LISTEN"; then
            # Additional wait for the service to fully initialize
            sleep 3
            log "JSON API is ready - Port 7575 is listening"
            return 0
        fi

        # Check for any success messages in log
        if tail -n 20 "../$LOG_FILE" | grep -qi "started\|ready\|listening"; then
            log "JSON API is ready - Startup message detected in logs"
            return 0
        fi

        log "JSON API not ready yet, waiting ${wait_seconds}s... ($((retry_count + 1))/$max_retries)"
        sleep $wait_seconds
        ((retry_count++))
    done

    # Last attempt to check health endpoint
    if curl -s http://localhost:7575/readyz 2>/dev/null | grep -q "readyz check passed"; then
        log "JSON API is ready - Final readyz check passed"
        return 0
    fi

    log "WARNING: JSON API failed to become ready after $((max_retries * wait_seconds)) seconds, but continuing anyway."
    log "Check $LOG_FILE for details. Services might still be starting in background."
    return 1
}

# Start JSON API
start_json_api() {
    log "Starting JSON API..."

    cd "$PROJECT_DIR"

    # Start JSON API in background and capture PID
    daml json-api --config json-api-app.conf >> "../$LOG_FILE" 2>&1 &
    JSON_API_PID=$!
    echo "$JSON_API_PID" > json_api.pid

    log "JSON API started with PID: $JSON_API_PID"
    log "JSON API is running on localhost:7575"

    # Wait for JSON API to be ready (non-fatal)
    if ! wait_for_json_api_ready; then
        log "JSON API readiness check failed, but process is still running in background"
    fi

    cd ..
}

# Verify both processes are running
verify_processes_running() {
    log "Verifying all processes are running..."

    local sandbox_pid
    local json_api_pid
    local all_running=true

    if [ -f "$PID_DIR/sandbox.pid" ]; then
        sandbox_pid=$(cat "$PID_DIR/sandbox.pid")
        if kill -0 $sandbox_pid 2>/dev/null; then
            log "✓ Canton Sandbox is running (PID: $sandbox_pid)"
        else
            log "✗ Canton Sandbox is not running (PID: $sandbox_pid)"
            all_running=false
        fi
    else
        log "✗ Canton Sandbox PID file not found"
        all_running=false
    fi

    if [ -f "$PID_DIR/json_api.pid" ]; then
        json_api_pid=$(cat "$PID_DIR/json_api.pid")
        if kill -0 $json_api_pid 2>/dev/null; then
            log "✓ JSON API is running (PID: $json_api_pid)"
        else
            log "✗ JSON API is not running (PID: $json_api_pid)"
            all_running=false
        fi
    else
        log "✗ JSON API PID file not found"
        all_running=false
    fi

    if [ "$all_running" = true ]; then
        log "All processes are running successfully"
        return 0
    else
        log "Some processes are not running, but continuing anyway"
        return 1
    fi
}

# Cleanup function for background processes
cleanup_processes() {
    log "Cleaning up background processes..."

    # Stop processes gracefully
    if [ -f "$PID_DIR/sandbox.pid" ] && kill -0 $(cat "$PID_DIR/sandbox.pid") 2>/dev/null; then
        log "Stopping Canton Sandbox..."
        kill $(cat "$PID_DIR/sandbox.pid")
        sleep 2
        log "Canton Sandbox stopped"
    fi

    if [ -f "$PID_DIR/json_api.pid" ] && kill -0 $(cat "$PID_DIR/json_api.pid") 2>/dev/null; then
        log "Stopping JSON API..."
        kill $(cat "$PID_DIR/json_api.pid")
        sleep 2
        log "JSON API stopped"
    fi

    # Clean up PID files
    rm -f "$PID_DIR/sandbox.pid" "$PID_DIR/json_api.pid" 2>/dev/null || true
    log "Cleanup completed"
}

# Wait for user interrupt
wait_for_interrupt() {
    log "All services have been started."
    log "Press Ctrl+C to stop all services"
    log "Services are running in background. Check $LOG_FILE for details."

    # Keep the script running indefinitely
    while true; do
        sleep 60
    done
}

# Main execution function
main() {
    log "Starting Canton Quest - Terminal 2 Setup"

    # Set trap for cleanup on script exit
    trap cleanup_processes EXIT INT TERM

    # Check if services are already running
    if check_existing_processes; then
        log "Services are already running. Attaching to existing processes."
    else
        log "Starting new services..."
        apply_bash_config
        start_canton_sandbox
        create_json_api_config
        start_json_api
    fi

    # Verify processes (non-fatal)
    verify_processes_running || true

    log "Terminal 2 setup completed successfully"
    log "Canton Sandbox and JSON API are running and ready"
    log "Check $LOG_FILE for detailed logs"

    # Keep script running and wait for interrupt
    wait_for_interrupt
}

# Run main function
main "$@"
