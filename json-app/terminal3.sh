#!/bin/bash

# Script: terminal3.sh
# Description: Interact with Canton using JSON API
# Author: Canton Quest

set -e

# Configuration
LOG_FILE="../canton_quest.log"
ENV_FILE="./json-app/.env-canton"
PROJECT_DIR="json-tests"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Apply bash configuration
apply_bash_config() {
    log "Applying bash configuration..."
    source "$HOME/.bashrc"
    log "Bash configuration applied"
}

# Generate JWT token function
generate_jwt_token() {
    log "Generating new JWT token..."

    # Load environment variables
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    fi

    if [ -z "$ALICE_IDENTIFIER" ]; then
        error_exit "ALICE_IDENTIFIER not found in environment"
    fi

    # Create JWT header
    local header='{
        "alg": "HS256",
        "typ": "JWT"
    }'

    # Create JWT payload
    local payload=$(cat <<EOF
{
    "https://daml.com/ledger-api": {
        "ledgerId": "sandbox",
        "applicationId": "HTTP-JSON-API-Gateway",
        "actAs": ["$ALICE_IDENTIFIER"]
    }
}
EOF
    )

    log "JWT Payload: $payload"

    # Base64Url encode function
    base64url_encode() {
        openssl base64 -e -A | tr '+/' '-_' | tr -d '='
    }

    # Create the encoded JWT parts
    local encoded_header=$(echo -n "$header" | base64url_encode)
    local encoded_payload=$(echo -n "$payload" | base64url_encode)

    local signing_key="secret"

    # Create signature
    local signature=$(echo -n "${encoded_header}.${encoded_payload}" | openssl dgst -sha256 -hmac "$signing_key" -binary | base64url_encode)

    # Create final JWT token
    local jwt_token="${encoded_header}.${encoded_payload}.${signature}"

    # Export the new JWT token
    export ALICE_JWT="$jwt_token"

    # Save to .env file for future use
    echo "ALICE_JWT=$jwt_token" >> "$ENV_FILE"

    log "New JWT token generated successfully"
    log "JWT Token: $jwt_token"
}

# Set JWT token
set_jwt_token() {
    log "Setting JWT token for Alice..."

    # Try to use generated token first, fallback to hardcoded one
    if [ -f "$ENV_FILE" ] && grep -q "ALICE_JWT" "$ENV_FILE"; then
        source "$ENV_FILE"
        log "Using JWT token from $ENV_FILE"
    else
        export ALICE_JWT='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwczovL2RhbWwuY29tL2xlZGdlci1hcGkiOnsibGVkZ2VySWQiOiJzYW5kYm94IiwiYXBwbGljYXRpb25JZCI6IkhUVFAtSlNPTi1BUEktR2F0ZXdheSIsImFjdEFzIjpbIkFsaWNlIl19fQ.FIjS4ao9yu1XYnv1ZL3t7ooPNIyQYAHY3pmzej4EMCM'
        log "Using hardcoded JWT token"
    fi

    log "JWT token set for Alice"
}

# Verify JSON API status
verify_json_api_status() {
    log "Verifying JSON API status..."

    local max_retries=10
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        local response
        response=$(curl -s -X GET localhost:7575/readyz || true)

        if echo "$response" | grep -q "readyz check passed"; then
            log "JSON API status: READY"
            echo "$response"
            return 0
        fi

        log "JSON API not ready yet, retrying... ($((retry_count + 1))/$max_retries)"
        sleep 5
        ((retry_count++))
    done

    error_exit "JSON API failed to become ready after $max_retries attempts"
}

# Allocate party
allocate_party() {
    log "Allocating party for Alice..."

    cd "$PROJECT_DIR"

    local response
    response=$(curl -s -d '{"identifierHint":"Alice"}' \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ALICE_JWT" \
        -X POST localhost:7575/v1/parties/allocate | jq)

    log "Party allocation response: $response"

    # Extract identifier
    local identifier
    identifier=$(echo "$response" | jq -r '.result.identifier')

    if [ -z "$identifier" ] || [ "$identifier" = "null" ]; then
        error_exit "Failed to extract party identifier from response"
    fi

    # Save to .env file
    echo "ALICE_IDENTIFIER=$identifier" >> "../$ENV_FILE"
    log "Alice identifier saved to $ENV_FILE: $identifier"

    cd ..
}

# Create user
create_user() {
    log "Creating user for Alice..."

    local response
    response=$(curl -s -H "Authorization: Bearer $ALICE_JWT" \
        -H 'Content-Type: application/json' \
        -d '{ "userId": "alice", "primaryParty": "Alice"}' \
        -X POST localhost:7575/v1/user/create | jq)

    log "User creation response: $response"

    local status
    status=$(echo "$response" | jq -r '.status')

    if [ "$status" != "200" ]; then
        error_exit "User creation failed with status: $status"
    fi

    log "User created successfully"
}

# Get package ID
get_package_id() {
    log "Obtaining package ID..."

    cd "$PROJECT_DIR"

    local package_id
    package_id=$(daml damlc inspect-dar .daml/dist/json-tests-*.dar | sed -n 's/.*json-tests-[^-]*-\([0-9a-f]\+\)\/Main\.daml.*/\1/p')

    if [ -z "$package_id" ]; then
        error_exit "Failed to extract package ID"
    fi

    log "Package ID obtained: $package_id"

    # Save to .env file
    echo "PACKAGE_ID=$package_id" >> "../$ENV_FILE"
    log "Package ID saved to $ENV_FILE"

    cd ..
}

# Load environment variables
load_env_variables() {
    log "Loading environment variables..."

    if [ ! -f "$ENV_FILE" ]; then
        error_exit "Environment file $ENV_FILE not found"
    fi

    source "$ENV_FILE"
    log "Environment variables loaded"
}

# Create contract creation JSON
create_contract_json() {
    log "Creating contract creation JSON..."

    cd "$PROJECT_DIR"

    # Load latest environment variables
    source "../$ENV_FILE"

    cat > create.json << EOF
{
  "templateId": "$PACKAGE_ID:Main:Asset",
  "payload": {
    "issuer": "$ALICE_IDENTIFIER",
    "owner": "$ALICE_IDENTIFIER",
    "name": "Example Asset Name"
  }
}
EOF

    log "Contract creation JSON file created: create.json"
    cd ..
}

# Submit contract creation
submit_contract_creation() {
    log "Submitting contract creation command..."

    cd "$PROJECT_DIR"

    local response
    response=$(curl -s -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ALICE_JWT" \
        -d @create.json \
        -X POST localhost:7575/v1/create | jq)

    log "Contract creation response: $response"

    local status
    status=$(echo "$response" | jq -r '.status')

    if [ "$status" != "200" ]; then
        error_exit "Contract creation failed with status: $status"
    fi

    log "Contract created successfully"
    cd ..
}

# Create query JSON
create_query_json() {
    log "Creating query JSON..."

    cd "$PROJECT_DIR"

    # Load latest environment variables
    source "../$ENV_FILE"

    cat > query.json << EOF
{
  "templateIds": [
    "$PACKAGE_ID:Main:Asset"
  ]
}
EOF

    log "Query JSON file created: query.json"
    cd ..
}

# Execute query
execute_query() {
    log "Executing contract query..."

    cd "$PROJECT_DIR"

    log "Executing command:"
    echo "curl -H \"Content-Type: application/json\" \\"
    echo "     -H \"Authorization: Bearer \$ALICE_JWT\" \\"
    echo "     -d @query.json \\"
    echo "     -X POST localhost:7575/v1/query | jq"

    local response
    response=$(curl -s -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ALICE_JWT" \
        -d @query.json \
        -X POST localhost:7575/v1/query | jq)

    log "Query response: $response"

    echo "Query Results:"
    echo "$response"

    cd ..
}

# Main execution function
main() {
    log "Starting Canton Quest - Terminal 3 Operations"

    apply_bash_config
    set_jwt_token
    verify_json_api_status
    allocate_party
    create_user
    get_package_id
    load_env_variables
    generate_jwt_token
    create_contract_json
    submit_contract_creation
    create_query_json

    # Execute contract query - direct command execution
    log "Executing contract query..."

    cd "$PROJECT_DIR"

    echo -e "\033[32m@$GITHUB_USER\033[0m \033[37m➜\033[0m \033[1;34m$PWD\033[0m \033[34m(\033[1;31mmain\033[34m)\033[0m \$ curl -H \"Content-Type: application/json\" \\\\"
    echo ">     -H \"Authorization: Bearer \$ALICE_JWT\" \\"
    echo ">     -d @query.json \\"
    echo ">     -X POST localhost:7575/v1/query | jq"
    # Just execute the command directly
    curl -H "Content-Type: application/json" \
         -H "Authorization: Bearer $ALICE_JWT" \
         -d @query.json \
         -X POST localhost:7575/v1/query | jq

    cd ..

}

# Run main function
main "$@"
