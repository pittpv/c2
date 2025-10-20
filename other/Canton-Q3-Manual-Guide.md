# 🧭 Canton Quest 3 — Полное руководство по прохождению вручную

Этот гайд объединяет шаги из terminal1.sh, terminal2.sh и terminal3.sh, чтобы вы могли выполнить квест вручную, сохраняя полученные данные в .env-canton для удобной подстановки.

## 🧩 Терминал 1: Установка Daml SDK и компиляция Daml модели

### Установка необходимых пакетов
```bash
sudo apt update
sudo apt install -y gnupg ca-certificates curl jq
```

### Установка Daml SDK 2.10.2
```bash
curl -sSL https://get.daml.com/ | sh -s 2.10.2
```

### Конфигурация Bash 

![Daml Path](../other/Скриншот%2020-10-2025%20190857.jpg)

После установки Daml SDK покажет путь (смотрите скриншот), скорпиуйте его и вставьте в вместо `<YOUR_PATH>`

```bash
export DAML_PATH=<YOUR_PATH>
export PATH="$DAML_PATH:$PATH"
echo "export PATH=\"$DAML_PATH:\$PATH\"" >> ~/.bashrc
```

### Установка Java JDK
```bash
curl -s https://repos.azul.com/azul-repo.key | sudo gpg --dearmor -o /usr/share/keyrings/azul.gpg
sudo chmod 644 /usr/share/keyrings/azul.gpg
echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" | sudo tee /etc/apt/sources.list.d/zulu.list
sudo apt update
sudo apt install -y zulu25-jdk
```

### Проверка установки
```bash
daml version
java -version
```

### Создание и компиляция Daml проекта
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

## 🚀 Терминал 2: Запуск Canton Sandbox

### Подготовка окружения
```bash
source ~/.bashrc
cd json-tests
```

### Запуск Canton Sandbox
```bash
DAR_FILE=$(find .daml/dist -name "json-tests-*.dar" | head -1)
daml sandbox --wall-clock-time --dar "$DAR_FILE"
```

## 🚀 Терминал 3: Запуск JSON API

### Подготовка окружения
```bash
source ~/.bashrc
cd json-tests
```

### Создание конфигурации JSON API
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

### Запуск JSON API
```bash
daml json-api --config json-api-app.conf
```

## 🧠 Терминал 4: Взаимодействие с Canton через JSON API

Откройте **новый терминал** (Sandbox должен работать параллельно).

### Создание файла для переменных окружения
```bash
source ~/.bashrc
touch .env-canton
```

### Создание участника (party) для Alice
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

### Создание пользователя
```bash
source .env-canton
curl -s -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJodHRwczovL2RhbWwuY29tL2xlZGdlci1hcGkiOnsibGVkZ2VySWQiOiJzYW5kYm94IiwiYXBwbGljYXRpb25JZCI6IkhUVFAtSlNPTi1BUEktR2F0ZXdheSIsImFjdEFzIjpbIkFsaWNlIl19fQ.FIjS4ao9yu1XYnv1ZL3t7ooPNIyQYAYAHY3pmzej4EMCM" \
    -H 'Content-Type: application/json' \
    -d '{ "userId": "alice", "primaryParty": "Alice"}' \
    -X POST localhost:7575/v1/user/create
```

### Получение ID пакета
```bash
cd json-tests
PACKAGE_ID=$(daml damlc inspect-dar .daml/dist/json-tests-*.dar | sed -n 's/.*json-tests-[^-]*-\([0-9a-f]\+\)\/Main\.daml.*/\1/p')
echo "PACKAGE_ID=$PACKAGE_ID" >> ../.env-canton
cd ..
```

### Загрузка переменных окружения
```bash
source .env-canton
```

### Создание JSON для контракта
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

### Генерация нового JWT токена для создания контракта
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

### Создание контракта с новым JWT токеном
```bash
curl -s -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ALICE_JWT_NEW" \
    -d @create.json \
    -X POST localhost:7575/v1/create
```

### Создание JSON для запроса 
```bash
cat > query.json << EOF
{
  "templateIds": [
    "$PACKAGE_ID:Main:Asset"
  ]
}
EOF
```
### Выполнение команды запроса

```bash
curl -H "Content-Type: application/json" \
     -H "Authorization: Bearer $ALICE_JWT_NEW" \
     -d @query.json \
     -X POST localhost:7575/v1/query | jq
```

## ✅ Результат

| Этап | Статус |
|------|--------|
| Daml SDK 2.10.2 установлен | ✅ |
| Java JDK установлен | ✅ |
| Проект `json-tests` создан и скомпилирован | ✅ |
| Canton Sandbox запущен | ✅ |
| JSON API запущен на порту 7575 | ✅ |
| Участник Alice создан | ✅ |
| Пользователь Alice создан | ✅ |
| JWT токен сгенерирован | ✅ |
| Контракт Asset успешно создан | ✅ |
| Запрос контрактов выполнен | 🎉 |

---

🧱 **Теперь вы завершили полный Daml Workflow Квест 3 вручную!**
