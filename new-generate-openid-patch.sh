#!/bin/bash

rm -f kong-new.yaml kong-new-patched.yaml

deck file openapi2kong -s sample-api.yaml -o kong-new.yaml
deck file patch -s kong-new.yaml -o kong-new-patched.yaml patches/add-openid-connect.yaml
deck --konnect-addr=https://eu.api.konghq.com --konnect-token=$KONNECT_TOKEN --konnect-runtime-group-name=nbim --select-tag=demo diff -s kong-new-patched.yaml
