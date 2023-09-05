#!/bin/bash

kced openapi2kong -s sample-api.yaml -o kong-new.yaml
kced merge ./patches/all-apis-plugins.yaml ./kong-new.yaml -o ./kong-new-patched.yaml
deck --konnect-addr=https://eu.api.konghq.com --konnect-token-file=$HOME/.passwords/konnect-pat.txt --konnect-runtime-group-name=test-rg-one --select-tag=demo diff -s kong-new.yaml
