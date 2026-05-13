#!/bin/bash

set -euo pipefail

ROLE_NAME="${1:-Scratch Org User Role}"
TARGET_ORG_ALIAS="${2:-}"

TARGET_ORG_ARG=""
if [ -n "$TARGET_ORG_ALIAS" ]; then
  TARGET_ORG_ARG="--target-org $TARGET_ORG_ALIAS"
fi

escape_soql_literal() {
  echo "$1" | sed "s/'/\\\\'/g"
}

ROLE_NAME_ESCAPED="$(escape_soql_literal "$ROLE_NAME")"
CURRENT_USERNAME="$(sf org display --verbose $TARGET_ORG_ARG --json | node -e "const fs=require('fs'); const input=JSON.parse(fs.readFileSync(0,'utf8')); process.stdout.write(input.result.username);")"
CURRENT_USERNAME_ESCAPED="$(escape_soql_literal "$CURRENT_USERNAME")"

CURRENT_USER_QUERY="SELECT Id, Username, UserRoleId FROM User WHERE Username = '$CURRENT_USERNAME_ESCAPED' LIMIT 1"
CURRENT_USER_JSON="$(sf data query --query "$CURRENT_USER_QUERY" $TARGET_ORG_ARG --json)"
CURRENT_USER_ID="$(echo "$CURRENT_USER_JSON" | node -e "const fs=require('fs'); const input=JSON.parse(fs.readFileSync(0,'utf8')); const rec=input.result.records?.[0]; if(!rec){process.exit(2)} process.stdout.write(rec.Id);")"
CURRENT_USER_USERNAME="$(echo "$CURRENT_USER_JSON" | node -e "const fs=require('fs'); const input=JSON.parse(fs.readFileSync(0,'utf8')); const rec=input.result.records?.[0]; if(!rec){process.exit(2)} process.stdout.write(rec.Username);")"
CURRENT_USER_ROLE_ID="$(echo "$CURRENT_USER_JSON" | node -e "const fs=require('fs'); const input=JSON.parse(fs.readFileSync(0,'utf8')); const rec=input.result.records?.[0]; if(!rec){process.exit(2)} process.stdout.write(rec.UserRoleId || '');")"

if [ -n "$CURRENT_USER_ROLE_ID" ]; then
  echo "Current user already has a role."
  echo "Username: $CURRENT_USER_USERNAME"
  echo "UserRoleId: $CURRENT_USER_ROLE_ID"
  exit 0
fi

ROLE_QUERY="SELECT Id, Name FROM UserRole WHERE Name = '$ROLE_NAME_ESCAPED' LIMIT 1"
ROLE_JSON="$(sf data query --query "$ROLE_QUERY" $TARGET_ORG_ARG --json)"
ROLE_ID="$(echo "$ROLE_JSON" | node -e "const fs=require('fs'); const input=JSON.parse(fs.readFileSync(0,'utf8')); process.stdout.write(input.result.records?.[0]?.Id || '');")"

if [ -z "$ROLE_ID" ]; then
  CREATE_ROLE_JSON="$(sf data create record --sobject UserRole --values \"Name=$ROLE_NAME\" $TARGET_ORG_ARG --json)"
  ROLE_ID="$(echo "$CREATE_ROLE_JSON" | node -e "const fs=require('fs'); const input=JSON.parse(fs.readFileSync(0,'utf8')); process.stdout.write(input.result.id);")"
  echo "Created role: $ROLE_NAME ($ROLE_ID)"
else
  echo "Using existing role: $ROLE_NAME ($ROLE_ID)"
fi

sf data update record --sobject User --record-id "$CURRENT_USER_ID" --values "UserRoleId=$ROLE_ID" $TARGET_ORG_ARG --json > /dev/null

echo "Assigned role to current user."
echo "Username: $CURRENT_USER_USERNAME"
echo "UserRoleId: $ROLE_ID"
