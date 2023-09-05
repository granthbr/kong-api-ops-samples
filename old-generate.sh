#!/bin/bash

rm -f kong-old.yaml

inso generate config sample-api.yaml --tags demo -k3 > kong-old.yaml

# OPTIONAL: new Inso supports automatic generation of _format_version 3.0 - just add "-k3" to the switches in inso
#deck convert --from kong-gateway-2.x --to kong-gateway-3.x --input-file kong-old.yaml --output-file kong-old.yaml --yes

deck --konnect-addr=https://eu.api.konghq.com --konnect-token-file=$HOME/.passwords/konnect-pat.txt --konnect-runtime-group-name=test-rg-one --select-tag=demo diff -s kong-old.yaml
