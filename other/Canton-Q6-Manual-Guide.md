
# 🧭 Canton Quest 6 — Полное руководство по прохождению вручную

Этот гайд объединяет шаги из `terminal6.sh`, `terminal7.sh` и `terminal8.sh`, чтобы вы могли **выполнить квест вручную**, сохраняя полученные данные (party ID, contract ID и т. д.) в `.env-canton` для удобной подстановки.

---

## ⚙️ Подготовка

**Убедитесь**, что:
- Установлен **Daml SDK**.
- Доступна команда `daml` в терминале.
- Установлен `jq` (для обработки JSON):

```bash
  sudo apt install jq -y
```

Создайте общий лог-файл:

```bash
touch canton_quest.log
```

---

## 🧩 Шаг 1 — Terminal 6: Установка Daml SDK и создание проекта

### 1. Установка нужной версии Daml

```bash
daml install 3.4.0-snapshot.20251013.0
```

### 2. Проверка версии

```bash
daml version
```

Убедитесь, что отображается:

```
3.4.0-snapshot.20251013.0 (default SDK version for new projects)
```

### 3. Создание проекта `capstone`

```bash
daml new capstone --template quickstart-java
```

После выполнения убедитесь, что появился файл:

```
./capstone/daml/Main.daml
```

### 4. Сборка проекта

```bash
cd capstone
daml build
```

После сборки должен появиться:

```
.daml/dist/quickstart-0.0.1.dar
```

### 5. Запуск тестов

```bash
daml test
```

Ожидаемый результат:

```
3 (100%) created
```

✅ Проект успешно создан и протестирован.

---

## 🚀 Шаг 2 — Terminal 7: Запуск Daml Sandbox и JSON API

Запускается в **отдельном терминале**.

### 1. Перейдите в проект:

```bash
cd capstone
```

### 2. Запустите Sandbox:

```bash
daml sandbox --json-api-port 7575
```

После инициализации появится строка:

```
Canton sandbox is ready
```

Sandbox запущен:

* Ledger: `localhost:6865`
* JSON API: `localhost:7575`

🟢 **Оставьте терминал открытым**, Sandbox должен работать, пока выполняется следующий этап.

---

## 🧠 Шаг 3 — Terminal 8: Работа с JSON API и бизнес-логикой

Откройте **новый терминал** (Sandbox должен работать параллельно).

---

### 1. Проверка доступности JSON API

```bash
curl http://localhost:7575/readyz
```

Если ответ пустой (код 200) — всё работает.

---

### 2. Создаём файл окружения `.env-canton`

В корне (рядом с `capstone/`) создайте файл:

```bash
touch .env-canton
```

Этот файл будет хранить все ID для подстановки в запросы.
Чтобы быстро подгружать их в сессию:

```bash
source .env-canton
```

---

### 3. Скачиваем OpenAPI спецификацию

```bash
cd capstone
curl -s localhost:7575/docs/openapi > openapi.yaml
```

---

### 4. Загружаем DAR пакет

```bash
curl -s -X POST 'http://localhost:7575/v2/packages' \
  -H "Content-Type: application/octet-stream" \
  --data-binary @.daml/dist/quickstart-0.0.1.dar
```

---

### 5. Создание участников (parties)

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

Проверяем:

```bash
cat ../.env-canton
```

---

### 6. Получаем ID пакета

```bash
PACKAGE_ID2=$(curl -s -X GET "http://localhost:7575/v2/interactive-submission/preferred-package-version?package-name=quickstart&parties=$ALICE_ID" | jq -r '.packagePreference.packageReference.packageId')
echo "PACKAGE_ID2=$PACKAGE_ID2" >> ../.env-canton
```

---

### 7. Выпускаем и переводим EUR → Alice

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

### 8. Выпускаем и переводим USD → Bob

Аналогично:

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

### 9. Принятие перевода Alice

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

### 10. Принятие перевода Bob

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

### 11. Добавление наблюдателя (observer)

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

### 12. Предложение сделки (Trade Proposal)

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

### 13. Принятие сделки (Trade Accept)

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

Запускаем финальный обмен:

```bash
curl -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \
  -H "Content-Type: application/json" \
  -d @accept_trade.json | jq .
```

---

## ✅ Результат

| Этап                                               | Статус |
| -------------------------------------------------- | ------ |
| Daml SDK 3.4.0-snapshot.20251013.0 установлен      | ✅      |
| Проект `capstone` создан и протестирован           | ✅      |
| Sandbox и JSON API запущены                        | ✅      |
| Участники (Alice, Bob, USD_Bank, EUR_Bank) созданы | ✅      |
| IOU переводы и обмен успешно выполнены             | ✅      |
| Финальный trade завершён                           | 🎉     |

---

## 💡 Полезные команды

Подгрузить переменные из `.env-canton`:

```bash
source ../.env-canton
```

Посмотреть сохранённые значения:

```bash
cat ../.env-canton
```

---

🧱 **Теперь вы завершили полный Daml Workflow Квест 6 вручную!**

