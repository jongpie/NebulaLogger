#!/bin/bash

SCRATCH_ORG_ALIAS="$1"

sf org create scratch --definition-file ./config/scratch-orgs/dev-scratch-def.json --alias $SCRATCH_ORG_ALIAS --duration-days 30 --set-default --json
wait

sf project deploy start -c
wait

npm run permset:assign:all
wait

sf apex run --file ./scripts/data/create-sample-log-entries.apex
wait

# These 2 commands require https://github.com/jamessimone/sf-trace-plugin
sf apex trace
sf lightning debug
