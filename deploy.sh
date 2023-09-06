#!/bin/bash
# prequesistes
# pass in the KONNECT_TOKEN as an environment variable

# install httpie

# setup and retrieve the API spec file


KONNECT_TOKEN=$2

# needed for the plugins , out of scope
TARGET=$(yq e '.info.x-deployment-target' $API_SPEC_FILE)

API_SPEC_FILE=$4
RUNTIME_GROUP_NAME=$3
URL=https://us.api.konghq.com

# pass in the target to the conditional below

# execute
deck file openapi2kong --spec $API_SPEC_FILE -o deck.yaml --select-tag $API_SPEC_FILE
deck --konnect-addr=$URL --konnect-token=$KONNECT_TOKEN --konnect-runtime-group-name=$RUNTIME_GROUP_NAME $1 -s deck.yaml --select-tag=$API_SPEC_FILE

if [ "$1" == "sync" ]
  then
  # swap servers block url(s) for the x-kong-proxy-url annotation
  export KONG_PROXY_URL="$(yq e '.info.x-kong-proxy-url' $API_SPEC_FILE)"
  echo "> Setting $KONG_PROXY_URL as the API spec's base URL"
  yq -i e '.servers[0].url |= env(KONG_PROXY_URL)' $API_SPEC_FILE
  yq -i e '.servers[0].description |= "Kong Production API Gateway Interface"' $API_SPEC_FILE

  # create API product; update it if it exists
  export API_NAME="$(yq e '.info.title' $API_SPEC_FILE)"
  export API_DESCRIPTION="$(yq e '.info.description' $API_SPEC_FILE)"
  export API_VERSION="$(yq e '.info.version' $API_SPEC_FILE)"
#   this is for the deptrectated functionality. Including for informational purposes
  export PORTAL_DEPRECATE="$(yq e '.info.x-deployment-portal-deprecated' $API_SPEC_FILE)"
  export PORTAL_PUBLISH="$(yq e '.info.x-deployment-portal-publish' $API_SPEC_FILE)"
  if [ "$PORTAL_PUBLISH" == "true" ]; then export PORTAL_PUBLISH="published"; else export PORTAL_PUBLISH="unpublished"; fi

  export CURRENT_PRODUCT_ID=$(http GET $URL/v2/api-products "Authorization: Bearer $KONNECT_TOKEN" | yq -P e '.data.[] | select(.name == env(API_NAME)).id')
  if [ -z "$CURRENT_PRODUCT_ID" ]
  then
    echo "> $API_NAME not found already in API Products - creating it..."
    export CURRENT_PRODUCT_ID=$(http POST $URL/v2/api-products "Authorization: Bearer $KONNECT_TOKEN" name="$API_NAME" description="$API_DESCRIPTION" | yq -P '.id')
  else
    echo "> $API_NAME already exists with ID $CURRENT_PRODUCT_ID"
    http PATCH "$URL/v2/api-products/$CURRENT_PRODUCT_ID" "Authorization: Bearer $KONNECT_TOKEN" name="$API_NAME" description="$API_DESCRIPTION" > /dev/null 2>&1
  fi

#   first the product must be created then,
#   create product version if it doesn't exist
  export CURRENT_PRODUCT_VERSION_ID=$(http GET "$URL/v2/api-products/$CURRENT_PRODUCT_ID/product-versions" "Authorization: Bearer $KONNECT_TOKEN" | yq -P e '.data.[] | select(.name == env(API_VERSION)).id')
  if [ -z "$CURRENT_PRODUCT_VERSION_ID" ]
  then
    echo "> Version $API_VERSION not found already in API Versions for $API_NAME - creating it..."
    export CURRENT_PRODUCT_VERSION_ID=$(http POST"$URL/v2/api-products/$CURRENT_PRODUCT_ID/product-versions" "Authorization: Bearer $KONNECT_TOKEN" name="$API_VERSION" | yq -P '.id')
  else
    echo "> Version $API_VERSION already exists for API $API_NAME with ID $CURRENT_PRODUCT_VERSION_ID"
  fi

  # upload the spec into this version, might as well overwrite the old one
  export CURRENT_API_SPEC_ID=$(http GET "$URL/v2/api-products/$CURRENT_PRODUCT_ID/product-versions/$CURRENT_PRODUCT_VERSION_ID/specifications" "Authorization: Bearer $KONNECT_TOKEN" | yq -P e '.data[0].id')
  if [ "$CURRENT_API_SPEC_ID" == "null" ]
  then
    echo "> Publishing spec document for API version $CURRENT_PRODUCT_VERSION_ID"
    http POST "$URL/v2/api-products$CURRENT_PRODUCT_ID/product-versions/$CURRENT_PRODUCT_VERSION_ID/specifications" "Authorization: Bearer $KONNECT_TOKEN" name="oas.yaml" "content"="$(cat $API_SPEC_FILE | base64 -b 0)"  > /dev/null 2>&1
  else
    echo "> API version $CURRENT_PRODUCT_VERSION_ID already has an API spec published - overwriting it"
    http PATCH "$URL/v2/api-products$CURRENT_PRODUCT_ID/product-versions/$CURRENT_PRODUCT_VERSION_ID/specifications/$CURRENT_API_SPEC_ID" "Authorization: Bearer $KONNECT_TOKEN" name="oas.yaml" "content"="$(cat $API_SPEC_FILE | base64 -b 0)" > /dev/null 2>&1
  fi

  # update portal publication settings
  echo "> Updating version $API_VERSION Portal publication status"
  http PATCH "$URL/v2/api-products$CURRENT_PRODUCT_ID/product-versions/$CURRENT_PRODUCT_VERSION_ID" "Authorization: Bearer $KONNECT_TOKEN" deprecated:=$PORTAL_DEPRECATE publish_status="$PORTAL_PUBLISH"
fi

echo ""
echo ">>> DONE"
echo ""