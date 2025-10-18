#!/bin/bash
# Script to create a new Daml project, copy json-app contents, and rename a file

set -e  # Exit immediately if a command fails

# 1. Create a new Daml project
echo "Creating a new Daml project 'persondata' from template 'skeleton'..."
daml new persondata --template skeleton

# Wait until the Main.daml file is created inside the project
echo "Waiting for ./persondata/daml/Main.daml to appear..."
while [ ! -f "./persondata/daml/Main.daml" ]; do
  sleep 1
done

# Update its timestamp (optional)
touch ./persondata/daml/Main.daml

echo "Project initialization complete. Continuing..."

# 2. Copy contents from json-app/persondata to persondata
echo "Copying contents from ./json-app/persondata to ./persondata..."
cp -r ./json-app/persondata/* ./persondata/

# 3. Remove Main.daml if it exists
if [ -f "./persondata/daml/Main.daml" ]; then
  echo "Removing ./persondata/daml/Main.daml..."
  rm ./persondata/daml/Main.daml
else
  echo "⚠️ Warning: ./persondata/daml/Main.daml not found. Skipping."
fi

echo "✅ Done! Project 'persondata' has been created and updated with json-app files."
echo "   Open 'persondata/daml/PersonData.daml' and click on Script result."
