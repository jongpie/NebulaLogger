#!/bin/bash

set -e

if sf org display --json > /dev/null 2>&1; then
  echo "Default org found, running startup script..."

  sf apex trace
  wait
  sf apex trace --is-autoproc-trace
  wait

  sf lightning debug
  wait

  ./auto-log-fetcher.sh
else
  echo "No default org set — skipping script."
fi