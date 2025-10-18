#!/bin/bash

# Script: terminal8.sh
# Description: Execute complex Daml workflow with JSON API v2
# Author: Canton Quest

set -e

# Configuration
LOG_FILE="../canton_quest.log"  # Лог в корневой директории
PROJECT_DIR="capstone"
ENV_FILE="../json-app/.env-canton"

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
    local max_wait=30
    local wait_time=0

    log "Waiting for file: $file_path"

    while [ $wait_time -lt $max_wait ]; do
        if [ -f "$file_path" ]; then
            log "File found: $file_path"
            return 0
        fi
        sleep 2
        ((wait_time+=2))
    done

    error_exit "File $file_path not found after ${max_wait} seconds"
}

# Save or update variable in environment file
save_to_env() {
    local var_name="$1"
    local var_value="$2"

    # Create file if it doesn't exist
    touch "$ENV_FILE"

    # Check if variable already exists
    if grep -q "^${var_name}=" "$ENV_FILE"; then
        # Update existing variable
        sed -i "s/^${var_name}=.*/${var_name}=${var_value}/" "$ENV_FILE"
        log "Updated in $ENV_FILE: ${var_name}=${var_value}"
    else
        # Add new variable
        echo "${var_name}=${var_value}" >> "$ENV_FILE"
        log "Saved to $ENV_FILE: ${var_name}=${var_value}"
    fi
}

# Debug function to log JSON responses
debug_json() {
    local context="$1"
    local json="$2"
    log "DEBUG $context: $json"
}

# Check if services are running
check_services() {
    log "Checking if JSON API is running..."
    if ! curl -s http://localhost:7575/readyz > /dev/null; then
        error_exit "JSON API is not running on port 7575. Please start terminal7.sh first."
    fi
    log "JSON API is running"
}

# Main execution function
main() {
    log "Starting Terminal 8 - Complex Daml Workflow"

    # Clean previous env file
    rm -f "$ENV_FILE"

    # Check if services are running
    check_services

    # Check if project directory exists
    if [ ! -d "$PROJECT_DIR" ]; then
        error_exit "Project directory '$PROJECT_DIR' not found. Please run terminal6.sh first."
    fi

    # Change to project directory
    cd "$PROJECT_DIR"
    log "Changed to project directory: $(pwd)"

    # Step 1: Download OpenAPI spec
    log "Step 1: Downloading OpenAPI specification"
    curl -s localhost:7575/docs/openapi > openapi.yaml
    wait_for_file "openapi.yaml"
    log "✓ OpenAPI specification downloaded"

    # Step 2: Upload DAR package
    log "Step 2: Uploading DAR package"
    local upload_response
    upload_response=$(curl -s -X POST 'http://localhost:7575/v2/packages' \
        -H "Content-Type: application/octet-stream" \
        --data-binary @.daml/dist/quickstart-0.0.1.dar)

    if [ $? -eq 0 ]; then
        log "✓ DAR package uploaded successfully"
    else
        error_exit "Failed to upload DAR package"
    fi

    # Step 3: Allocate parties
    log "Step 3: Allocating parties"

    # Allocate Alice
    log "Allocating Alice party..."
    local alice_response
    alice_response=$(curl -s -d '{"partyIdHint":"Alice", "identityProviderId": ""}' \
        -H "Content-Type: application/json" \
        -X POST localhost:7575/v2/parties)
    debug_json "Alice allocation" "$alice_response"

    ALICE_ID=$(echo "$alice_response" | jq -r '.partyDetails.party')
    if [ -z "$ALICE_ID" ] || [ "$ALICE_ID" = "null" ]; then
        error_exit "Failed to extract Alice party. Response: $alice_response"
    fi

    save_to_env "ALICE_ID" "$ALICE_ID"
    log "✓ Alice party allocated: $ALICE_ID"

    # Allocate Bob
    log "Allocating Bob party..."
    local bob_response
    bob_response=$(curl -s -d '{"partyIdHint":"Bob", "identityProviderId": ""}' \
        -H "Content-Type: application/json" \
        -X POST localhost:7575/v2/parties)
    debug_json "Bob allocation" "$bob_response"

    BOB_ID=$(echo "$bob_response" | jq -r '.partyDetails.party')
    if [ -z "$BOB_ID" ] || [ "$BOB_ID" = "null" ]; then
        error_exit "Failed to extract Bob party. Response: $bob_response"
    fi

    save_to_env "BOB_ID" "$BOB_ID"
    log "✓ Bob party allocated: $BOB_ID"

    # Allocate USD Bank
    log "Allocating USD_Bank party..."
    local usd_bank_response
    usd_bank_response=$(curl -s -d '{"partyIdHint":"USD_Bank", "identityProviderId": ""}' \
        -H "Content-Type: application/json" \
        -X POST localhost:7575/v2/parties)
    debug_json "USD Bank allocation" "$usd_bank_response"

    USD_BANK=$(echo "$usd_bank_response" | jq -r '.partyDetails.party')
    if [ -z "$USD_BANK" ] || [ "$USD_BANK" = "null" ]; then
        error_exit "Failed to extract USD_Bank party. Response: $usd_bank_response"
    fi

    save_to_env "USD_BANK" "$USD_BANK"
    log "✓ USD Bank party allocated: $USD_BANK"

    # Allocate EUR Bank
    log "Allocating EUR_Bank party..."
    local eur_bank_response
    eur_bank_response=$(curl -s -d '{"partyIdHint":"EUR_Bank", "identityProviderId": ""}' \
        -H "Content-Type: application/json" \
        -X POST localhost:7575/v2/parties)
    debug_json "EUR Bank allocation" "$eur_bank_response"

    EUR_BANK=$(echo "$eur_bank_response" | jq -r '.partyDetails.party')
    if [ -z "$EUR_BANK" ] || [ "$EUR_BANK" = "null" ]; then
        error_exit "Failed to extract EUR_Bank party. Response: $eur_bank_response"
    fi

    save_to_env "EUR_BANK" "$EUR_BANK"
    log "✓ EUR Bank party allocated: $EUR_BANK"

    # Step 4: List parties
    log "Step 4: Listing parties"
    daml ledger list-parties >> "$LOG_FILE" 2>&1
    log "✓ Parties listed"

    # Step 5: Get package ID
    log "Step 5: Getting package ID"
    local package_response
    package_response=$(curl -s -X GET "http://localhost:7575/v2/interactive-submission/preferred-package-version?package-name=quickstart&parties=$ALICE_ID")
    debug_json "Package ID" "$package_response"

    PACKAGE_ID2=$(echo "$package_response" | jq -r '.packagePreference.packageReference.packageId')
    if [ -z "$PACKAGE_ID2" ] || [ "$PACKAGE_ID2" = "null" ]; then
        error_exit "Failed to get package ID. Response: $package_response"
    fi

    save_to_env "PACKAGE_ID2" "$PACKAGE_ID2"
    log "✓ Package ID obtained: $PACKAGE_ID2"

    # Step 6: Create and execute EUR transfer
    log "Step 6: Creating EUR transfer for Alice"
    cat > issue_eur.json << EOF
{
"commands": {
"commands": [
   {
     "CreateAndExerciseCommand": {
       "templateId": "$PACKAGE_ID2:Iou:Iou",
       "createArguments": {
         "issuer": "$EUR_BANK",
         "owner": "$EUR_BANK",
         "currency": "EUR",
         "amount": "100.0",
         "observers": []
       },
       "choice": "Iou_Transfer",
       "choiceArgument": {
         "newOwner": "$ALICE_ID"
       }
     }
   }
 ],
 "userId": "eur-bank-user",
 "commandId": "issue-eur-to-alice-1",
 "actAs": [
   "$EUR_BANK"
 ]
}
}
EOF

    local eur_transfer_response
    eur_transfer_response=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
        -H "Content-Type: application/json" \
        -d @issue_eur.json)
    debug_json "EUR transfer" "$eur_transfer_response"

    ALICE_TRANSFER_CID=$(echo "$eur_transfer_response" | jq -r '.transaction.events[0].CreatedEvent.contractId')
    if [ -z "$ALICE_TRANSFER_CID" ] || [ "$ALICE_TRANSFER_CID" = "null" ]; then
        error_exit "Failed to extract EUR transfer contract ID. Response: $eur_transfer_response"
    fi

    save_to_env "ALICE_TRANSFER_CID" "$ALICE_TRANSFER_CID"
    log "✓ EUR transfer created: $ALICE_TRANSFER_CID"

    # Step 7: Create and execute USD transfer
    log "Step 7: Creating USD transfer for Bob"
    cat > issue_usd.json << EOF
{
"commands": {
"commands": [
   {
     "CreateAndExerciseCommand": {
       "templateId": "$PACKAGE_ID2:Iou:Iou",
       "createArguments": {
         "issuer": "$USD_BANK",
         "owner": "$USD_BANK",
         "currency": "USD",
         "amount": "110.0",
         "observers": []
       },
       "choice": "Iou_Transfer",
       "choiceArgument": {
         "newOwner": "$BOB_ID"
       }
     }
   }
 ],
 "userId": "usd-bank-user",
 "commandId": "issue-usd-to-bob-1",
 "actAs": [
   "$USD_BANK"
 ]
}
}
EOF

    local usd_transfer_response
    usd_transfer_response=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
        -H "Content-Type: application/json" \
        -d @issue_usd.json)
    debug_json "USD transfer" "$usd_transfer_response"

    BOB_TRANSFER_CID=$(echo "$usd_transfer_response" | jq -r '.transaction.events[0].CreatedEvent.contractId')
    if [ -z "$BOB_TRANSFER_CID" ] || [ "$BOB_TRANSFER_CID" = "null" ]; then
        error_exit "Failed to extract USD transfer contract ID. Response: $usd_transfer_response"
    fi

    save_to_env "BOB_TRANSFER_CID" "$BOB_TRANSFER_CID"
    log "✓ USD transfer created: $BOB_TRANSFER_CID"

    # Step 8: Alice accepts EUR transfer
    log "Step 8: Alice accepting EUR transfer"
    cat > alice_trf.json << EOF
{
 "commands": {
 "commands": [
   {
     "ExerciseCommand": {
       "templateId": "$PACKAGE_ID2:Iou:IouTransfer",
       "contractId": "$ALICE_TRANSFER_CID",
       "choice": "IouTransfer_Accept",
       "choiceArgument": {}
     }
   }
 ],
 "userId": "alice-user",
 "commandId": "alice-accept-eur-transfer",
 "actAs": [
   "$ALICE_ID"
 ]
}
}
EOF

    local alice_accept_response
    alice_accept_response=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
        -H "Content-Type: application/json" \
        -d @alice_trf.json)
    debug_json "Alice accept EUR" "$alice_accept_response"

    # Extract contractId from the second event (CreatedEvent)
    ALICE_ACCEPT_EUR=$(echo "$alice_accept_response" | jq -r '.transaction.events[1].CreatedEvent.contractId')
    if [ -z "$ALICE_ACCEPT_EUR" ] || [ "$ALICE_ACCEPT_EUR" = "null" ]; then
        # Try alternative: find first CreatedEvent
        ALICE_ACCEPT_EUR=$(echo "$alice_accept_response" | jq -r '.transaction.events[] | select(.CreatedEvent?) | .CreatedEvent.contractId' | head -1)
        if [ -z "$ALICE_ACCEPT_EUR" ] || [ "$ALICE_ACCEPT_EUR" = "null" ]; then
            error_exit "Failed to extract Alice accept EUR contract ID. Response: $alice_accept_response"
        fi
    fi

    LATEST_OFFSET=$(echo "$alice_accept_response" | jq -r '.transaction.offset')
    if [ -z "$LATEST_OFFSET" ] || [ "$LATEST_OFFSET" = "null" ]; then
        error_exit "Failed to extract offset. Response: $alice_accept_response"
    fi

    save_to_env "ALICE_ACCEPT_EUR" "$ALICE_ACCEPT_EUR"
    save_to_env "LATEST_OFFSET" "$LATEST_OFFSET"
    log "✓ Alice accepted EUR transfer: $ALICE_ACCEPT_EUR"
    log "✓ Latest offset: $LATEST_OFFSET"

    # Step 9: Bob accepts USD transfer
    log "Step 9: Bob accepting USD transfer"
    cat > bob_trf.json << EOF
{
 "commands": {
 "commands": [
   {
     "ExerciseCommand": {
       "templateId": "$PACKAGE_ID2:Iou:IouTransfer",
       "contractId": "$BOB_TRANSFER_CID",
       "choice": "IouTransfer_Accept",
       "choiceArgument": {}
     }
   }
 ],
 "userId": "bob-user",
 "commandId": "bob-accept-usd-transfer",
 "actAs": [
   "$BOB_ID"
 ]
}
}
EOF

    local bob_accept_response
    bob_accept_response=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
        -H "Content-Type: application/json" \
        -d @bob_trf.json)
    debug_json "Bob accept USD" "$bob_accept_response"

    # Extract contractId from the second event (CreatedEvent)
    BOB_ACCEPT_USD=$(echo "$bob_accept_response" | jq -r '.transaction.events[1].CreatedEvent.contractId')
    if [ -z "$BOB_ACCEPT_USD" ] || [ "$BOB_ACCEPT_USD" = "null" ]; then
        # Try alternative: find first CreatedEvent
        BOB_ACCEPT_USD=$(echo "$bob_accept_response" | jq -r '.transaction.events[] | select(.CreatedEvent?) | .CreatedEvent.contractId' | head -1)
        if [ -z "$BOB_ACCEPT_USD" ] || [ "$BOB_ACCEPT_USD" = "null" ]; then
            error_exit "Failed to extract Bob accept USD contract ID. Response: $bob_accept_response"
        fi
    fi

    save_to_env "BOB_ACCEPT_USD" "$BOB_ACCEPT_USD"
    log "✓ Bob accepted USD transfer: $BOB_ACCEPT_USD"

# Step 10: Get active contracts
    log "Step 10: Getting active contracts"
    cat > acs.json << EOF
{
  "filter": {
    "filtersByParty": {
      "$ALICE_ID": {
        "cumulative": [
          {
            "identifierFilter": {
              "TemplateFilter": {
                "value": {
                  "templateId": "$PACKAGE_ID2:Iou:Iou",
                  "includeCreatedEventBlob": true
                }
              }
            }
          }
        ]
      },
      "$BOB_ID": {
        "cumulative": [
          {
            "identifierFilter": {
              "TemplateFilter": {
                "value": {
                  "templateId": "$PACKAGE_ID2:Iou:Iou",
                  "includeCreatedEventBlob": true
                }
              }
            }
          }
        ]
      }
    }
  },
  "verbose": true,
  "activeAtOffset": "$LATEST_OFFSET"
}
EOF

    curl -s -X POST 'http://localhost:7575/v2/state/active-contracts' \
        -H "Content-Type: application/json" \
        -d @acs.json | jq . > acs_response.json
    log "✓ Active contracts retrieved"

    # Step 11: Add observer
    log "Step 11: Adding Bob as observer to Alice's IOU"
    cat > add_observer.json << EOF
{
  "commands": {
    "commands": [
      {
        "ExerciseCommand": {
          "templateId": "$PACKAGE_ID2:Iou:Iou",
          "contractId": "$ALICE_ACCEPT_EUR",
          "choice": "Iou_AddObserver",
          "choiceArgument": {
            "newObserver": "$BOB_ID"
          }
        }
      }
],
"userId": "alice-user",
    "commandId": "iou-disclosure-split-1",
    "actAs": [
      "$ALICE_ID"
]
}
}
EOF

    local observer_response
    observer_response=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
        -H "Content-Type: application/json" \
        -d @add_observer.json)
    debug_json "NEW_IOU" "$observer_response"

    # Extract contractId from the second event (CreatedEvent)
    NEW_IOU=$(echo "$observer_response" | jq -r '.transaction.events[1].CreatedEvent.contractId')
    if [ -z "$NEW_IOU" ] || [ "$NEW_IOU" = "null" ]; then
        # Try alternative: find first CreatedEvent
        NEW_IOU=$(echo "$observer_response" | jq -r '.transaction.events[] | select(.CreatedEvent?) | .CreatedEvent.contractId' | head -1)
        if [ -z "$NEW_IOU" ] || [ "$NEW_IOU" = "null" ]; then
            error_exit "Failed to extract NEW_IOU contract ID. Response: $observer_response"
        fi
    fi

    save_to_env "NEW_IOU" "$NEW_IOU"
    log "✓ Observer added, new IOU: $NEW_IOU"

    # Step 12: Propose trade
    log "Step 12: Proposing trade"
    cat > propose_trade.json << EOF
{
  "commands": {
    "commands": [
            {
        "CreateCommand": {
          "templateId": "$PACKAGE_ID2:IouTrade:IouTrade",
          "createArguments": {
            "buyer": "$ALICE_ID",
            "seller": "$BOB_ID",
            "baseIouCid": "$NEW_IOU",
            "baseIssuer": "$EUR_BANK",
            "baseCurrency": "EUR",
            "baseAmount": "100.0",
            "quoteIssuer": "$USD_BANK",
            "quoteCurrency": "USD",
            "quoteAmount": "110.0"
          }
        }
      }
    ],
    "userId": "alice-user",
    "commandId": "trade-proposal-1",
    "actAs": [
      "$ALICE_ID"
    ]
  }
}
EOF

    local trade_proposal_response
    trade_proposal_response=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
        -H "Content-Type: application/json" \
        -d @propose_trade.json)
    debug_json "Trade proposal" "$trade_proposal_response"

    # For CreateCommand, there should be only one CreatedEvent
    TRADE_PROPOSAL_CID=$(echo "$trade_proposal_response" | jq -r '.transaction.events[0].CreatedEvent.contractId')
    if [ -z "$TRADE_PROPOSAL_CID" ] || [ "$TRADE_PROPOSAL_CID" = "null" ]; then
        # Try alternative: find first CreatedEvent
        TRADE_PROPOSAL_CID=$(echo "$trade_proposal_response" | jq -r '.transaction.events[] | select(.CreatedEvent?) | .CreatedEvent.contractId' | head -1)
        if [ -z "$TRADE_PROPOSAL_CID" ] || [ "$TRADE_PROPOSAL_CID" = "null" ]; then
            error_exit "Failed to extract trade proposal contract ID. Response: $trade_proposal_response"
        fi
    fi

    save_to_env "TRADE_PROPOSAL_CID" "$TRADE_PROPOSAL_CID"
    log "✓ Trade proposed: $TRADE_PROPOSAL_CID"

    # Step 13: Accept trade
    log "Step 13: Accepting trade"
    cat > accept_trade.json << EOF
{
 "commands": {
   "commands": [
     {
       "ExerciseCommand": {
         "templateId": "$PACKAGE_ID2:IouTrade:IouTrade",
         "contractId": "$TRADE_PROPOSAL_CID",
         "choice": "IouTrade_Accept",
         "choiceArgument": {
           "quoteIouCid": "$BOB_ACCEPT_USD"
         }
       }
     }
   ],
   "userId": "bob-user",
   "commandId": "trade-acceptance-1",
   "actAs": [
     "$BOB_ID"
   ]
 }
}
EOF

    echo "================================================"
    echo "Final step: Executing trade acceptance"
    echo "Command:"
    echo "curl -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d @accept_trade.json | jq ."
    echo "================================================"

    # Execute the final command directly in terminal
    curl -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
        -H "Content-Type: application/json" \
        -d @accept_trade.json | jq .
}

# Run main function
main "$@"
