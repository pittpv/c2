# 🧭 Canton Quest 3 — Complete Manual Walkthrough

This guide combines steps from terminal1.sh, terminal2.sh, and terminal3.sh, allowing you to perform the quest manually while saving the obtained data to .env-canton for convenient substitution.

## 🧩 Terminal 1: Install Daml SDK and Compile Daml Model

### Install necessary packages
```bash
sudo apt update
sudo apt install -y gnupg ca-certificates curl jq
```

### Install Daml SDK 2.10.2

```bash
curl -sSL https://get.daml.com/ | sh -s 2.10.2
```

### Bash Configuration 

![Daml Path](../other/Скриншот%2020-10-2025%20190857.jpg)

After installing the Daml SDK, it will show the path (see the screenshot), copy it and paste it instead of `<YOUR_PATH>`

```bash
export DAML_PATH=<YOUR_PATH>
export PATH="$DAML_PATH:$PATH"
echo "export PATH=\"$DAML_PATH:\$PATH\"" >> ~/.bashrc
```

### Install Java JDK
```bash
curl -s https://repos.azul.com/azul-repo.key | sudo gpg --dearmor -o /usr/share/keyrings/azul.gpg
sudo chmod 644 /usr/share/keyrings/azul.gpg
echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" | sudo tee /etc/apt/sources.list.d/zulu.list
sudo apt update
sudo apt install -y zulu25-jdk
```

### Verify installation
```bash
daml version
java -version
```

### Create and compile Daml project
```bash
daml new json-tests
```
```bash
cd json-tests
daml build
```
```bash
cd ..
```

## 🚀 Terminal 2: Launch Canton Sandbox

### Prepare environment
```bash
source ~/.bashrc
cd json-tests
```

### Launch Canton Sandbox
```bash
DAR_FILE=$(find .daml/dist -name "json-tests-*.dar" | head -1)
daml sandbox --wall-clock-time --dar "$DAR_FILE"
```

## 🚀 Terminal 3: Launch JSON API

### Prepare environment
```bash
source ~/.bashrc
cd json-tests
```

### Create JSON API configuration
```bash
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
```

### Launch JSON API
```bash
daml json-api --config json-api-app.conf
```

## 🧠 Terminal 4: Interact with Canton via JSON API

Open a **new terminal** (Sandbox must be running in parallel).

### Create file for environment variables
```bash
source ~/.bashrc
touch .env-canton
```

### Create a party for Alice
```bash
cd json-tests
RESPONSE=$(curl -s -d '{"identifierHint":"Alice"}' \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwczovL2RhbWwuY29tL2xlZGdlci1hcGkiOnsibGVkZ2VySWQiOiJzYW5kYm94IiwiYXBwbGljYXRpb25JZCI6IkhUVFAtSlNPTi1BUEktR2F0ZXdheSIsImFjdEFzIjpbIkFsaWNlIl19fQ.FIjS4ao9yu1XYnv1ZL3t7ooPNIyQYAYAHY3pmzej4EMCM" \
    -X POST localhost:7575/v1/parties/allocate)
ALICE_IDENTIFIER=$(echo $RESPONSE | jq -r '.result.identifier')
echo "ALICE_IDENTIFIER=$ALICE_IDENTIFIER" >> ../.env-canton
cd ..
```

### Create user
```bash
source .env-canton
curl -s -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwczovL2RhbWwuY29tL2xlZGdlci1hcGkiOnsibGVkZ2VySWQiOiJzYW5kYm94IiwiYXBwbGljYXRpb25JZCI6IkhUVFAtSlNPTi1BUEktR2F0ZXdheSIsImFjdEFzIjpbIkFsaWNlIl19fQ.FIjS4ao9yu1XYnv1ZL3t7ooPNIyQYAYAHY3pmzej4EMCM" \
    -H 'Content-Type: application/json' \
    -d '{ "userId": "alice", "primaryParty": "Alice"}' \
    -X POST localhost:7575/v1/user/create
```

### Get package ID
```bash
cd json-tests
PACKAGE_ID=$(daml damlc inspect-dar .daml/dist/json-tests-*.dar | sed -n 's/.*json-tests-[^-]*-\([0-9a-f]\+\)\/Main\.daml.*/\1/p')
echo "PACKAGE_ID=$PACKAGE_ID" >> ../.env-canton
cd ..
```

### Load environment variables
```bash
source .env-canton
```

### Create JSON for contract
```bash
cd json-tests
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
```

### Generate new JWT token for contract creation
```bash
header='{
    "alg": "HS256",
    "typ": "JWT"
}'

payload=$(cat <<EOF
{
    "https://daml.com/ledger-api": {
        "ledgerId": "sandbox",
        "applicationId": "HTTP-JSON-API-Gateway",
        "actAs": ["$ALICE_IDENTIFIER"]
    }
}
EOF
)

base64url_encode() {
    openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

encoded_header=$(echo -n "$header" | base64url_encode)
encoded_payload=$(echo -n "$payload" | base64url_encode)
signing_key="secret"
signature=$(echo -n "${encoded_header}.${encoded_payload}" | openssl dgst -sha256 -hmac "$signing_key" -binary | base64url_encode)
NEW_JWT_TOKEN="${encoded_header}.${encoded_payload}.${signature}"

export ALICE_JWT_NEW="$NEW_JWT_TOKEN"
echo "ALICE_JWT_NEW=$NEW_JWT_TOKEN" >> ../.env-canton
```

### Create contract with new JWT token
```bash
curl -s -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ALICE_JWT_NEW" \
    -d @create.json \
    -X POST localhost:7575/v1/create
```

### Create JSON for query
```bash
cat > query.json << EOF
{
  "templateIds": [
    "$PACKAGE_ID:Main:Asset"
  ]
}
EOF
```
### Execute query command

```bash
curl -H "Content-Type: application/json" \
     -H "Authorization: Bearer $ALICE_JWT_NEW" \
     -d @query.json \
     -X POST localhost:7575/v1/query | jq
```

## ✅ Result

| Stage | Status |
|------|--------|
| Daml SDK 2.10.2 installed | ✅ |
| Java JDK installed | ✅ |
| Project `json-tests` created and compiled | ✅ |
| Canton Sandbox launched | ✅ |
| JSON API launched on port 7575 | ✅ |
| Party Alice created | ✅ |
| User Alice created | ✅ |
| JWT token generated | ✅ |
| Asset contract successfully created | ✅ |
| Contract query executed | 🎉 |

---

🧱 **You have now completed the full Daml Workflow Quest 3 manually!**
