#!/bin/bash

set -euo pipefail

NETWORK_NAME="${1:-}"
AUTH_PROVIDER_DEVELOPER_NAME="${2:-}"
TARGET_ORG_ALIAS="${3:-}"

if [ -z "$NETWORK_NAME" ] || [ -z "$AUTH_PROVIDER_DEVELOPER_NAME" ]; then
  echo "Usage: sh ./scripts/dev/link-community-auth-provider.sh <network-name> <auth-provider-developer-name> [target-org-alias]"
  exit 1
fi

TARGET_ORG_ARG=""
if [ -n "$TARGET_ORG_ALIAS" ]; then
  TARGET_ORG_ARG="--target-org $TARGET_ORG_ALIAS"
fi

escape_soql_literal() {
  # Escape single quotes for safe SOQL literals.
  echo "$1" | sed "s/'/\\\\'/g"
}

NETWORK_NAME_ESCAPED="$(escape_soql_literal "$NETWORK_NAME")"
PROVIDER_NAME_ESCAPED="$(escape_soql_literal "$AUTH_PROVIDER_DEVELOPER_NAME")"

NETWORK_QUERY="SELECT Id, Name, UrlPathPrefix FROM Network WHERE Name = '$NETWORK_NAME_ESCAPED' LIMIT 1"
NETWORK_JSON="$(sf data query --query "$NETWORK_QUERY" $TARGET_ORG_ARG --json)"

NETWORK_ID="$(echo "$NETWORK_JSON" | node -e "const fs=require('fs');const input=JSON.parse(fs.readFileSync(0,'utf8'));const records=input.result.records||[];if(records.length===0){process.exit(2)};process.stdout.write(records[0].Id)")"
NETWORK_URL_PREFIX="$(echo "$NETWORK_JSON" | node -e "const fs=require('fs');const input=JSON.parse(fs.readFileSync(0,'utf8'));const records=input.result.records||[];if(records.length===0){process.exit(2)};process.stdout.write(records[0].UrlPathPrefix || '')")"

if [ -z "$NETWORK_ID" ] || [ -z "$NETWORK_URL_PREFIX" ]; then
  echo "Could not find Network '$NETWORK_NAME' or its UrlPathPrefix."
  exit 1
fi

AUTH_PROVIDER_QUERY="SELECT Id, DeveloperName FROM AuthProvider WHERE DeveloperName = '$PROVIDER_NAME_ESCAPED' LIMIT 1"
AUTH_PROVIDER_JSON="$(sf data query --query "$AUTH_PROVIDER_QUERY" $TARGET_ORG_ARG --json)"
AUTH_PROVIDER_ID="$(echo "$AUTH_PROVIDER_JSON" | node -e "const fs=require('fs');const input=JSON.parse(fs.readFileSync(0,'utf8'));const records=input.result.records||[];if(records.length===0){process.exit(2)};process.stdout.write(records[0].Id)")"

if [ -z "$AUTH_PROVIDER_ID" ]; then
  echo "Could not find AuthProvider with DeveloperName '$AUTH_PROVIDER_DEVELOPER_NAME'."
  exit 1
fi

AUTH_CONFIG_QUERY="SELECT Id, DeveloperName, Url, AuthOptionsAuthProvider FROM AuthConfig WHERE Type = 'Community' AND Url LIKE '%/$NETWORK_URL_PREFIX' LIMIT 1"
AUTH_CONFIG_JSON="$(sf data query --query "$AUTH_CONFIG_QUERY" $TARGET_ORG_ARG --json)"
AUTH_CONFIG_ID="$(echo "$AUTH_CONFIG_JSON" | node -e "const fs=require('fs');const input=JSON.parse(fs.readFileSync(0,'utf8'));const records=input.result.records||[];if(records.length===0){process.exit(2)};process.stdout.write(records[0].Id)")"

if [ -z "$AUTH_CONFIG_ID" ]; then
  echo "Could not find AuthConfig for Network '$NETWORK_NAME' (urlPathPrefix '$NETWORK_URL_PREFIX')."
  exit 1
fi

echo "Network: $NETWORK_NAME ($NETWORK_ID)"
echo "AuthProvider: $AUTH_PROVIDER_DEVELOPER_NAME ($AUTH_PROVIDER_ID)"
echo "AuthConfig: $AUTH_CONFIG_ID"

LINK_QUERY="SELECT Id FROM AuthConfigProviders WHERE AuthConfigId = '$AUTH_CONFIG_ID' AND AuthProviderId = '$AUTH_PROVIDER_ID' LIMIT 1"
LINK_JSON="$(sf data query --query "$LINK_QUERY" $TARGET_ORG_ARG --json)"
EXISTING_LINK_ID="$(echo "$LINK_JSON" | node -e "const fs=require('fs');const input=JSON.parse(fs.readFileSync(0,'utf8'));const records=input.result.records||[];process.stdout.write(records[0]?.Id || '')")"

if [ -n "$EXISTING_LINK_ID" ]; then
  echo "Auth provider is already linked (AuthConfigProviders.Id=$EXISTING_LINK_ID)."
else
  sf data create record --sobject AuthConfigProviders --values "AuthConfigId=$AUTH_CONFIG_ID AuthProviderId=$AUTH_PROVIDER_ID" $TARGET_ORG_ARG --json > /dev/null
  echo "Linked auth provider to community login configuration."
fi

echo "Done."
