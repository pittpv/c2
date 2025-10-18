#!/bin/bash
# Script to create a new Daml project and copy json-app contents

set -e  # Exit immediately if a command fails

# 1. Create a new Daml project
echo "Creating a new Daml project 'intro1' from template 'daml-intro-1'..."
daml new intro1 --template daml-intro-1

# 2. Copy contents from json-app/intro1 to intro1
echo "Copying contents from ./json-app/intro1 to ./intro1..."
cp -r ./json-app/intro1/* ./intro1/

echo "✅ Done! Project 'intro1' has been created and updated with json-app files. Open file 'intro1/daml/Token.daml' and click on Script result "
