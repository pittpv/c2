#!/bin/bash

# Script: terminal1.sh
# Description: Setup Daml SDK and compile Daml model
# Author: Canton Quest

set -e

# Configuration
LOG_FILE="canton_quest.log"
ENV_FILE="./json-app/.env-canton"
BASHRC_FILE="$HOME/.bashrc"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Cleanup previous installations
cleanup_previous_installations() {
    log "Cleaning up previous installations..."

    # Remove created directories and log files
    rm -rf json-tests
    rm -f "$LOG_FILE" "$ENV_FILE"

    log "Cleanup completed"
}

# Install Daml SDK
install_daml_sdk() {
    log "Installing Daml SDK version 2.10.2..."

    # Download and install Daml SDK
    curl -sSL https://get.daml.com/ | sh -s 2.10.2 2>&1 | tee -a "$LOG_FILE"

    # Extract path from installation output
    DAML_PATH=$(grep "Please add" "$LOG_FILE" | sed -n 's/.*Please add \(.*\)\/bin to your PATH.*/\1/p')

    if [ -z "$DAML_PATH" ]; then
        error_exit "Failed to extract Daml SDK path"
    fi

    log "Daml SDK path extracted: $DAML_PATH"

    # Save path to .env-canton file
    echo "DAML_PATH=$DAML_PATH" > "$ENV_FILE"
    log "Daml SDK path saved to $ENV_FILE"
}

# Configure bashrc
configure_bashrc() {
    log "Configuring $BASHRC_FILE..."

    local daml_path
    daml_path=$(grep "DAML_PATH" "$ENV_FILE" | cut -d'=' -f2)

    if [ -z "$daml_path" ]; then
        error_exit "DAML_PATH not found in $ENV_FILE"
    fi

    local path_export="export PATH=\"$daml_path/bin:\$PATH\""

    # Create or update .bashrc
    if [ ! -f "$BASHRC_FILE" ]; then
        log "Creating $BASHRC_FILE"
        touch "$BASHRC_FILE"
    fi

    # Remove existing Daml path if present
    grep -v "DAML_PATH\|daml.*bin" "$BASHRC_FILE" > "$BASHRC_FILE.tmp" 2>/dev/null || true
    mv "$BASHRC_FILE.tmp" "$BASHRC_FILE" 2>/dev/null || true

    # Add new path export
    echo "$path_export" >> "$BASHRC_FILE"
    log "PATH export added to $BASHRC_FILE"

    # Apply changes to current shell session
    export PATH="$daml_path/bin:$PATH"
    log "PATH updated in current session: $daml_path/bin added to PATH"
}

# Verify Daml installation
verify_daml_installation() {
    log "Verifying Daml installation..."

    # Give the system a moment to recognize the new PATH
    sleep 2

    if ! command -v daml &> /dev/null; then
        log "Daml command not found directly, trying alternative approach..."

        # Try to find daml executable directly
        local daml_path
        daml_path=$(grep "DAML_PATH" "$ENV_FILE" | cut -d'=' -f2)

        if [ -f "$daml_path/bin/daml" ]; then
            log "Found daml executable at: $daml_path/bin/daml"
            # Use full path to daml for verification
            "$daml_path/bin/daml" version >> "$LOG_FILE" 2>&1
            log "Daml version check completed successfully using direct path"
        else
            error_exit "Daml command not found after installation and PATH configuration"
        fi
    else
        daml version >> "$LOG_FILE" 2>&1
        log "Daml version check completed successfully"
    fi
}

# Install OpenJDK
install_openjdk() {
    log "Installing OpenJDK and essential tools..."

    # Install prerequisites
    sudo apt update >> "$LOG_FILE" 2>&1
    sudo apt install -y gnupg ca-certificates curl >> "$LOG_FILE" 2>&1

    # Add Azul repository
    curl -s https://repos.azul.com/azul-repo.key | sudo gpg --dearmor -o /usr/share/keyrings/azul.gpg
    sudo chmod 644 /usr/share/keyrings/azul.gpg

    echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" | sudo tee /etc/apt/sources.list.d/zulu.list

    # Update and install JDK
    sudo apt update >> "$LOG_FILE" 2>&1
    echo "Y" | sudo apt install -y zulu25-jdk >> "$LOG_FILE" 2>&1

    log "OpenJDK installation completed"
}

# Install additional tools
install_additional_tools() {
    log "Installing additional tools..."

    sudo apt-get install -y jq >> "$LOG_FILE" 2>&1
    log "Additional tools installation completed"
}

# Create and compile Daml model
create_daml_model() {
    log "Creating Daml model 'json-tests'..."

    # Get daml path for direct execution if needed
    local daml_path
    daml_path=$(grep "DAML_PATH" "$ENV_FILE" | cut -d'=' -f2)

    # Use daml command directly or via full path
    if command -v daml &> /dev/null; then
        daml new json-tests >> "$LOG_FILE" 2>&1
    else
        "$daml_path/bin/daml" new json-tests >> "$LOG_FILE" 2>&1
    fi

    log "Building Daml model..."
    cd json-tests

    if command -v daml &> /dev/null; then
        daml build >> "../$LOG_FILE" 2>&1
    else
        "$daml_path/bin/daml" build >> "../$LOG_FILE" 2>&1
    fi

    cd ..

    log "Daml model created and compiled successfully"
}

# Main execution function
main() {
    log "Starting Canton Quest - Terminal 1 Setup"

    cleanup_previous_installations
    install_daml_sdk
    configure_bashrc
    verify_daml_installation
    install_openjdk
    install_additional_tools
    create_daml_model

    log "Terminal 1 setup completed successfully"
}

# Run main function
main "$@"
