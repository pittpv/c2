# 🧭 Canton Quest 6 — Complete Manual Walkthrough Guide

This guide combines steps from `terminal6.sh`, `terminal7.sh`, and `terminal8.sh`, allowing you to **complete the quest manually** while saving obtained data (party ID, contract ID, etc.) to `.env-canton` for convenient substitution.

## Video of the process (8 minutes)

https://x.com/pittpv/status/1980689185997746679

---

## ⚙️ Preparation

**Ensure** that:
- **Daml SDK** is installed.
- The `daml` command is available in the terminal.
- `jq` is installed (for JSON processing):

```bash
  sudo apt install jq -y
```

Create a shared log file:

```bash
touch canton_quest.log
```

---

## 🧩 Step 1 — Terminal 6: Install Daml SDK and Create Project

### 1. Install the Required Daml Version

```bash
daml install 3.4.0-snapshot.20251013.0
```

### 2. Check Version

```bash
daml version
```

Ensure it displays:

```
3.4.0-snapshot.20251013.0 (default SDK version for new projects)
```

### 3. Create the `capstone` Project

```bash
daml new capstone --template quickstart-java
```

After execution, ensure this file exists:

```
./capstone/daml/Main.daml
```

### 4. Build the Project

```bash
cd capstone
daml build
```

After building, this should appear:

```
.daml/dist/quickstart-0.0.1.dar
```

### 5. Run Tests

```bash
daml test
```

Expected result:

```
3 (100%) created
```

✅ Project successfully created and tested.

---

## 🚀 Step 2 — Terminal 7: Start Daml Sandbox and JSON API

Run this in a **separate terminal**.

### 1. Navigate to the project:

```bash
cd capstone
```

### 2. Start the Sandbox:

```bash
daml sandbox --json-api-port 7575
```

After initialization, this line will appear:

```
Canton sandbox is ready
```

Sandbox is running:

* Ledger: `localhost:6865`
* JSON API: `localhost:7575`

🟢 **Keep this terminal open**; the Sandbox must remain running while the next stage executes.

---

## 🧠 Step 3 — Terminal 8: Work with JSON API and Business Logic

Open a **new terminal** (Sandbox should be running in parallel).

---

### 1. Check JSON API Availability

```bash
curl http://localhost:7575/readyz
```

If the response is empty (code 200) — everything is working.

---

### 2. Create the `.env-canton` Environment File

In the root directory (next to `capstone/`), create the file:

```bash
touch .env-canton
```

This file will store all IDs for substitution in requests.
To quickly load them into your session:

```bash
source .env-canton
```

---

### 3. Download the OpenAPI Specification

```bash
cd capstone
curl -s localhost:7575/docs/openapi > openapi.yaml
```

---

### 4. Upload the DAR Package

```bash
curl -s -X POST 'http://localhost:7575/v2/packages' \
  -H "Content-Type: application/octet-stream" \
  --data-binary @.daml/dist/quickstart-0.0.1.dar
```

---

### 5. Create Parties

#### Alice

```bash
ALICE_ID=$(curl -s -d '{"partyIdHint":"Alice","identityProviderId":""}' \
  -H "Content-Type: application/json" \
  -X POST localhost:7575/v2/parties | jq -r '.partyDetails.party')
echo "ALICE_ID=$ALICE_ID" >> ../.env-canton
```

#### Bob

```bash
BOB_ID=$(curl -s -d '{"partyIdHint":"Bob","identityProviderId":""}' \
  -H "Content-Type: application/json" \
  -X POST localhost:7575/v2/parties | jq -r '.partyDetails.party')
echo "BOB_ID=$BOB_ID" >> ../.env-canton
```

#### USD_Bank

```bash
USD_BANK=$(curl -s -d '{"partyIdHint":"USD_Bank","identityProviderId":""}' \
  -H "Content-Type: application/json" \
  -X POST localhost:7575/v2/parties | jq -r '.partyDetails.party')
echo "USD_BANK=$USD_BANK" >> ../.env-canton
```

#### EUR_Bank

```bash
EUR_BANK=$(curl -s -d '{"partyIdHint":"EUR_Bank","identityProviderId":""}' \
  -H "Content-Type: application/json" \
  -X POST localhost:7575/v2/parties | jq -r '.partyDetails.party')
echo "EUR_BANK=$EUR_BANK" >> ../.env-canton
```

Check:

```bash
cat ../.env-canton
```

---

### 6. Get the Package ID

```bash
PACKAGE_ID2=$(curl -s -X GET "http://localhost:7575/v2/interactive-submission/preferred-package-version?package-name=quickstart&parties=$ALICE_ID" | jq -r '.packagePreference.packageReference.packageId')
echo "PACKAGE_ID2=$PACKAGE_ID2" >> ../.env-canton
```

---

### 7. Issue and Transfer EUR → Alice

```bash
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
   "actAs": ["$EUR_BANK"]
 }
}
EOF
```

```bash
ALICE_TRANSFER_CID=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
  -H "Content-Type: application/json" \
  -d @issue_eur.json | jq -r '.transaction.events[0].CreatedEvent.contractId')
echo "ALICE_TRANSFER_CID=$ALICE_TRANSFER_CID" >> ../.env-canton
```

---

### 8. Issue and Transfer USD → Bob

Similarly:

```bash
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
   "actAs": ["$USD_BANK"]
 }
}
EOF
```

```bash
BOB_TRANSFER_CID=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
  -H "Content-Type: application/json" \
  -d @issue_usd.json | jq -r '.transaction.events[0].CreatedEvent.contractId')
echo "BOB_TRANSFER_CID=$BOB_TRANSFER_CID" >> ../.env-canton
```

---

### 9. Alice Accepts the Transfer

```bash
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
   "actAs": ["$ALICE_ID"]
 }
}
EOF
```

```bash
ALICE_ACCEPT_EUR=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
  -H "Content-Type: application/json" \
  -d @alice_trf.json | jq -r '.transaction.events[] | select(.CreatedEvent?) | .CreatedEvent.contractId' | head -1)
echo "ALICE_ACCEPT_EUR=$ALICE_ACCEPT_EUR" >> ../.env-canton
```

---

### 10. Bob Accepts the Transfer

```bash
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
   "actAs": ["$BOB_ID"]
 }
}
EOF
```

```bash
BOB_ACCEPT_USD=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
  -H "Content-Type: application/json" \
  -d @bob_trf.json | jq -r '.transaction.events[] | select(.CreatedEvent?) | .CreatedEvent.contractId' | head -1)
echo "BOB_ACCEPT_USD=$BOB_ACCEPT_USD" >> ../.env-canton
```

---

### 11. Add an Observer

```bash
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
   "actAs": ["$ALICE_ID"]
 }
}
EOF
```

```bash
NEW_IOU=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
  -H "Content-Type: application/json" \
  -d @add_observer.json | jq -r '.transaction.events[] | select(.CreatedEvent?) | .CreatedEvent.contractId' | head -1)
echo "NEW_IOU=$NEW_IOU" >> ../.env-canton
```

---

### 12. Propose a Trade

```bash
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
   "actAs": ["$ALICE_ID"]
 }
}
EOF
```

```bash
TRADE_PROPOSAL_CID=$(curl -s -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
  -H "Content-Type: application/json" \
  -d @propose_trade.json | jq -r '.transaction.events[0].CreatedEvent.contractId')
echo "TRADE_PROPOSAL_CID=$TRADE_PROPOSAL_CID" >> ../.env-canton
```

---

### 13. Accept the Trade

```bash
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
   "actAs": ["$BOB_ID"]
 }
}
EOF
```

Execute the final exchange:

```bash
curl -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
  -H "Content-Type: application/json" \
  -d @accept_trade.json | jq .
```

---

## ✅ Result

| Stage                                               | Status |
| --------------------------------------------------- | ------ |
| Daml SDK 3.4.0-snapshot.20251013.0 installed        | ✅      |
| Project `capstone` created and tested               | ✅      |
| Sandbox and JSON API running                        | ✅      |
| Parties (Alice, Bob, USD_Bank, EUR_Bank) created    | ✅      |
| IOU transfers and exchange successfully executed    | ✅      |
| Final trade completed                               | 🎉     |

---

## 💡 Useful Commands

Load variables from `.env-canton`:

```bash
source ../.env-canton
```

View saved values:

```bash
cat ../.env-canton
```

---

🧱 **You have now completed the full Daml Workflow Quest 6 manually!**
