# Canton Quest - Daml Developer Quests 

**Description in:**
- [🇷🇺 На Русском](https://github.com/pittpv/canton-dev-quests/tree/main/ "Русская версия описания")

![First screen](../other/Canton-Homepage-Hero-Banner.png)

This repository contains scripts for completing [Canton quests](https://earn.stackup.dev/campaigns/unlocking-canton-with-daml-unifying-traditional-and-crypto-markets-on-chain). To avoid any issues, please strictly follow the order (preparing, copying, and completing quests) and instructions. If you have any questions, please contact me via Telegram at the bottom of this description.

⚠️ Deadline: Oct 24, 2025, 12:00 (GMT +08:00)

## Prerequisites

👇🏻 Click and read
<details>

### 1. Install Visual Studio Code

Download and install VS Code from: https://code.visualstudio.com/

### 2. Create Repository
![Create Repository](../other/Скриншот%2017-10-2025%20202938.jpg)

Enter any repository name:

![Repository Name](../other/Скриншот%2017-10-2025%20203049.jpg)

You can make it private:

![Private Repository](../other/Скриншот%2017-10-2025%20203127.jpg)

Click "Create repository":

![Create Button](../other/Скриншот%2017-10-2025%20203142.jpg)

Create an empty README file:

![Create README](../other/Скриншот%2017-10-2025%20203221.jpg)

Make initial commit:

![Initial Commit](../other/Скриншот%2017-10-2025%20203241.jpg)
![Commit Confirmation](../other/Скриншот%2017-10-2025%20203303.jpg)

### 3. Create GitHub Codespace
Click to create codespace:

![Create Codespace](../other/Скриншот%2017-10-2025%20203334.jpg)

Select previously created repository:

![Select Repository](../other/Скриншот%2017-10-2025%20203428.jpg)

Create codespace:

![Create Codespace](../other/Скриншот%2017-10-2025%20203453.jpg)

### 4. Install Daml Extension
When codespace is ready, install the Daml extension:
- Click extensions button (1)
- Search for "daml" (2)
- Click Install (3)

![Install Daml Extension](../other/Скриншот%2017-10-2025%20203551.jpg)

Agree and install:

![Install Confirmation](../other/Скриншот%2017-10-2025%20203625.jpg)

### 5. Connect Desktop VS Code
Click to open in desktop VS Code:

![Open in Desktop](../other/Скриншот%2017-10-2025%20203657.jpg)

Click "Open here":

![Open Here](../other/Скриншот%2017-10-2025%20203740.jpg)

Confirm in desktop:

![Desktop Confirmation](../other/Скриншот%2017-10-2025%20203803.jpg)

**Note:** The program will show several windows - agree to all prompts and install everything requested for GitHub connection.

</details>

### Clone Files and Set Permissions

Execute the commands one by one:
```bash
git clone https://github.com/pittpv/canton-dev-quests.git

mv ./canton-dev-quests/json-app ./

rm -rf ./canton-dev-quests && chmod +x /json-app/terminal*.sh
```

## Quests

Each script is named `terminal1.sh`, `terminal2.sh`, etc. Each script should be run in a separate terminal. After running the first script, immediately open the log file `/canton_quest.log` to see additional information.

You don't need scripts for quests 1 and 2. Complete these quests yourself.

### Quest 3

<details>

(Keep all terminals open until quest completion)

#### Terminal 1
Open terminal:

![Open Terminal](../other/Скриншот%2017-10-2025%20203925.jpg)

Run first script:
```bash
bash ./json-app/terminal1.sh
```

Wait for completion:

![Terminal 1 Complete](../other/Скриншот%2017-10-2025%20204715.jpg)

#### Terminal 2
Open new terminal and run:
```bash
bash ./json-app/terminal2.sh
```

Wait for messages:

![Terminal 2 Running](../other/Скриншот%2017-10-2025%20211721.jpg)

#### Terminal 3
Open new terminal and run:
```bash
bash ./json-app/terminal3.sh
```

Wait for completion:

![Terminal 3 Complete](../other/Скриншот%2017-10-2025%20224752.jpg)

**Screenshot requirements:**

- The last curl command
- Your full screen, including your taskbar (Windows / Linux) or dock (MacOS)
- The entire output of the command, including the contractId and templateId.

**Screenshot recommendations:**
- Expand file folder (1 on screenshot)
- Close log file (2 on screenshot)
- Scroll terminal window to this line (3 on screenshot)
- Resize window to show bottom area (4 on screenshot)

Save screenshot as: `C52Q3_YourStackupLogin.png` or `.jpg`

**Now press Ctrl+C in the second terminal and close all three terminals.**
</details>

### Quest 4

<details>

Open new terminal and run:
```bash
bash ./json-app/terminal4.sh
```

Wait for completion:

![Terminal 4 Complete](../other/Скриншот%2018-10-2025%20104316.jpg)

Click on first "Script result" - a schema window will open. Check the box (2 on screenshot).

Hold Alt key and click button (1 on screenshot) to open new window (3 on screenshot).

![Terminal 4 details](../other/Скриншот%2018-10-2025%20104626.jpg)

Click on second "Script result" and drag the schema down. Check the box as in previous schema.

Repeat with third "Script result", don't forget to check the box.

Take full window screenshot - should look like:

![Quest 4 Result](../other/Скриншот%2018-10-2025%20104831.jpg)

**Screenshot requirements:**

- The code for token_test_1, token_test_2 and token_archive_exercise
- Script results of token_test_2
- Script results of token_archive_exercise
- Your full screen, including your taskbar (Windows / Linux) or dock (MacOS)

Save as: `C52Q4_YourStackupLogin.png` or `.jpg`

You can close the terminal.
</details>

### Quest 5

<details>

Open new terminal and run:
```bash
bash ./json-app/terminal5.sh
```

Wait for completion:

![Terminal 5 Complete](../other/Скриншот%2018-10-2025%20112605.jpg)

Open `PersonData.daml` file in folder (3 on screenshot).

Click on "Script result" (1 on screenshot). A schema window will open. Check the box (2 on screenshot).

Take full window screenshot - should match the example:

![Quest 5 Result](../other/Скриншот%2018-10-2025%20112605.jpg)

**Screenshot requirements:**

- The table for PersonData:PersonData. In particular, it must show the contact column.
- Show archived checkbox is checked
- Your full screen, including your taskbar (Windows / Linux) or dock (MacOS)

Save as: `C52Q5_YourStackupLogin.png` or `.jpg`

You can close the terminal.
</details>

### Quest 6

<details>

(Keep all terminals open until quest completion)

#### Terminal 1
Open new terminal and run:
```bash
bash ./json-app/terminal6.sh
```

Wait for completion:

![Terminal 6 Complete](../other/Скриншот%2018-10-2025%20192352.jpg)

#### Terminal 2
Open new terminal and run:
```bash
bash ./json-app/terminal7.sh
```

Wait for messages:

![Terminal 7 Running](../other/Скриншот%2018-10-2025%20192422.jpg)

#### Terminal 3
Open new terminal and run:
```bash
bash ./json-app/terminal8.sh
```

Wait for completion:

![Terminal 8 Complete](../other/Скриншот%2018-10-2025%20192518.jpg)

**Screenshot requirements:**

- The createArgument segment of the command curl -X POST 'http://localhost:7575/v2/commands/submit-and-wait-for-transaction' \-H "Content-Type: application/json" \-d @accept_trade.json | jq .
- Issuer is EUR_BANK, Owner is Bob
- Currency is EUR and amount is 100
- createdAt field shown clearly
- Your full screen, including your taskbar (Windows / Linux) or dock (MacOS)

**Screenshot recommendations:**

- Expand `capstone` folder
- Close log file
- Scroll terminal window to appropriate location

Save screenshot as: `C52Q6_YourStackupLogin.png` or `.jpg`

**Now press Ctrl+C in the seventh terminal and close all three terminals.**
</details>

## Script Descriptions

- **terminal1.sh**: Daml SDK installation and environment setup
- **terminal2.sh**: Canton Sandbox and JSON API startup
- **terminal3.sh**: JSON API interactions and contract operations
- **terminal4.sh**: Daml model visualization and analysis
- **terminal5.sh**: PersonData contract operations
- **terminal6.sh**: Capstone project creation and testing
- **terminal7.sh**: Sandbox with JSON API for capstone
- **terminal8.sh**: Complex workflow with JSON API v2

## Logging

All scripts log to `canton_quest.log` in the root directory. Monitor this file for detailed execution information and debugging.

## Troubleshooting

- Ensure all prerequisites are installed
- Run scripts in separate terminals as instructed
- Check log file for detailed error information
- Verify file permissions with `chmod +x ./json-app/terminal*.sh`

Good luck with your quests! 🚀

## ✍️ Feedback

Author [Pittpv](https://x.com/pittpv)

**Donate**

- EVM: `0x4FD5eC033BA33507E2dbFE57ca3ce0A6D70b48Bf`
- SOL: `C9TV7Q4N77LrKJx4njpdttxmgpJ9HGFmQAn7GyDebH4R`

For any issues, suggestions, or feedback:

[https://t.me/+DLsyG6ol3SFjM2Vk](https://t.me/+DLsyG6ol3SFjM2Vk)

## 🔗 Useful Links

[One-click RPC setup script](https://github.com/pittpv/sepolia-auto-install "Quickly set up a Sepolia node for RPC")
