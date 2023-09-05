#!/bin/bash

rm -f kong-new.yaml kong-new-patched.yaml

deck file openapi2kong -s sample-api.yaml -o kong-new.yaml --select-tag demo
deck --konnect-addr=https://eu.api.konghq.com --konnect-token-file=$HOME/.passwords/konnect-pat.txt --konnect-runtime-group-name=test-rg-one --select-tag=demo diff -s kong-new.yaml
