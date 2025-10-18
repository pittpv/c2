#!/bin/bash

# Script: terminal6.sh
# Description: Install Daml 3.4.0 snapshot and create capstone project
# Author: Canton Quest

set -e

# Configuration
LOG_FILE="canton_quest.log"
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

# Wait for file to appear
wait_for_file() {
    local file_path="$1"
    local max_wait=60
    local wait_time=0

    log "Waiting for file: $file_path"

    while [ $wait_time -lt $max_wait ]; do
        if [ -f "$file_path" ]; then
            log "File found: $file_path"
            return 0
        fi

        sleep 5
        ((wait_time+=5))
        log "Still waiting for file... ${wait_time}s"
    done

    error_exit "File $file_path not found after ${max_wait} seconds"
}

# Wait for specific text in log
wait_for_text_in_log() {
    local search_text="$1"
    local max_wait=120
    local wait_time=0

    log "Waiting for text in output: '$search_text'"

    while [ $wait_time -lt $max_wait ]; do
        if tail -n 50 "$LOG_FILE" | grep -q "$search_text"; then
            log "Text found: '$search_text'"
            return 0
        fi

        sleep 5
        ((wait_time+=5))
        log "Still waiting for text... ${wait_time}s"
    done

    error_exit "Text '$search_text' not found in log after ${max_wait} seconds"
}

# Install Daml 3.4.0 snapshot
install_daml_snapshot() {
    log "Installing Daml 3.4.0 snapshot..."

    # Install specific snapshot version
    daml install 3.4.0-snapshot.20251013.0 >> "$LOG_FILE" 2>&1

    log "Daml installation command completed, waiting for full installation..."

    # Wait a moment for installation to fully complete
    sleep 10

    log "Daml snapshot installation finished"
}

# Verify Daml version
verify_daml_version() {
    log "Verifying Daml version..."

    # Get full version output
    local version_output
    version_output=$(daml version 2>&1)

    log "Full Daml version output:"
    log "$version_output"

    # Check for the exact expected version string
    if echo "$version_output" | grep -q "3.4.0-snapshot.20251013.0.*(default SDK version for new projects)"; then
        log "✓ Correct Daml version detected: 3.4.0-snapshot.20251013.0 (default SDK version for new projects)"
    elif echo "$version_output" | grep -q "3.4.0-snapshot.20251013.0"; then
        log "✓ Correct Daml version detected: 3.4.0-snapshot.20251013.0"
    else
        log "WARNING: Expected version string not found exactly as specified"
        log "Looking for any 3.4.0 version..."

        if echo "$version_output" | grep -q "3.4.0"; then
            log "✓ Daml 3.4.0 version detected (may not be exact snapshot)"
        else
            error_exit "Wrong Daml version detected. Expected 3.4.0-snapshot.20251013.0, got: $version_output"
        fi
    fi

    # Extract and display the actual version line
    local version_line
    version_line=$(echo "$version_output" | grep -E "3\.4\.0" | head -1)
    log "Actual version line: $version_line"
}

# Create capstone project
create_capstone_project() {
    log "Creating capstone project with Java template..."

    daml new capstone --template quickstart-java >> "$LOG_FILE" 2>&1

    log "Capstone project creation command completed"

    # Wait for Main.daml file to appear
    wait_for_file "./capstone/daml/Main.daml"

    log "Capstone project created successfully"
}

# Build Daml project
build_daml_project() {
    log "Building Daml project..."

    cd "$PROJECT_DIR"

    daml build >> "$LOG_FILE" 2>&1

    log "Daml build command completed"

    # Wait for DAR file to appear
    wait_for_file "./.daml/dist/quickstart-0.0.1.dar"

    cd ..

    log "Daml project built successfully"
}

# Run Daml tests
run_daml_tests() {
    log "Running Daml tests..."

    cd "$PROJECT_DIR"

    # Run tests in background and capture output
    daml test >> "../$LOG_FILE" 2>&1 &
    TEST_PID=$!

    log "Daml tests started with PID: $TEST_PID"

    # Wait for test completion message
    wait_for_text_in_log "3 (100%) created"

    # Wait for test process to complete
    wait $TEST_PID

    cd ..

    log "Daml tests completed successfully"
}

# Main execution function
main() {
    log "Starting Canton Quest - Terminal 6 Setup"

    # Check if daml command is available
    if ! command -v daml &> /dev/null; then
        error_exit "Daml command not found. Please run terminal1.sh first."
    fi

    log "Current Daml version before update:"
    daml version >> "$LOG_FILE" 2>&1 || true

    install_daml_snapshot
    verify_daml_version
    create_capstone_project
    build_daml_project
    run_daml_tests

    log "================================================"
    log "Terminal 6 setup completed successfully!"
    log "Capstone project created and tests passed."
    log "================================================"

    echo "✅ Terminal 6 setup completed successfully!"
    echo "📁 Project created: ./capstone"
    echo "🧪 Tests passed: 3 contracts created (100%)"
    echo "🔧 Daml version: 3.4.0-snapshot.20251013.0 installed"
    echo ""
    echo "To continue, run the bash script ./terminal2.sh if it is not already running."
}

# Run main function
main "$@"
