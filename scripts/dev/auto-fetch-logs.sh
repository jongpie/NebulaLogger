#!/bin/bash

LOG_DIR=./logs
POLL_INTERVAL=10 # seconds

mkdir -p "$LOG_DIR"

echo "Watching for new Apex logs from default org..."
KNOWN_IDS=()

while true; do
  # Fetch log list in JSON
  LOGS_JSON=$(sf apex log list --json 2>/dev/null)

  # Extract log IDs (most recent first)
  NEW_IDS=($(echo "$LOGS_JSON" | jq -r '.result[].id'))

  for ID in "${NEW_IDS[@]}"; do
    if [[ ! " ${KNOWN_IDS[*]} " =~ " $ID " ]]; then
      echo "📥 Fetching new log: $ID"
      sf apex log get --log-id "$ID" --output-dir "$LOG_DIR"
      KNOWN_IDS+=("$ID")
    fi
  done

  sleep "$POLL_INTERVAL"
done
