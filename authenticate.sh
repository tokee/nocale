#!/bin/bash

#
# Authenticates a specific user. See https://developer.health.nokia.com/api
#

###############################################################################
# CONFIG
###############################################################################

pushd ${BASH_SOURCE%/*} > /dev/null
if [[ -s authenticate.conf ]]; then
    source authenticate.conf
fi
if [[ -s nokia_scale.conf ]]; then
    source nokia_scale.conf
fi

: ${API_KEY:=""}    # aka consumer key
: ${API_SECRET:=""} # aka consumer secret
: ${USERID:=""} # Digits

: ${API_REQUEST_TOKEN:="https://developer.health.nokia.com/account/request_token"}
: ${API_REQUEST_TOKEN_CALLBACK:="http://example.com"} # Not really used as we script it all
: ${OAUTH_SIGNATURE_METHOD:="HMAC-SHA1"}
: ${OAUTH_VERSION:="1.0"}

popd > /dev/null

function usage() {
    echo "Usage: ./authenticate.sh"
    exit $1
}

check_parameters() {
    if [[ -z "$API_KEY" || -z "$API_SECRET" || -z "$USERID" ]]; then
        echo "Error: Please state API_KEY, API_SECRET & USERID"
        usage 2
    fi
}

################################################################################
# FUNCTIONS
################################################################################

function escape() {
    sed -e 's/%/%25/g' -e 's/:/%3A/g' -e 's/\//%2F/g' -e 's/=/%3D/g' -e 's/&/%26/g' -e 's/+/%2B/g' <<< "$1"
}

# Step 1 : get a oAuth "request token"
# https://developer.health.nokia.com/api#step1
function request_token() {
    local TIMESTAMP=$(date +%s)
    local NONCE=$(uuidgen)
    # Yes, callback must be double-escaped
    local BASE_STRING="GET&$(escape "$API_REQUEST_TOKEN")&oauth_callback%3D$(escape $(escape "$API_REQUEST_TOKEN_CALLBACK"))%26oauth_consumer_key%3D${API_KEY}%26oauth_nonce%3D${NONCE}%26oauth_signature_method%3D${OAUTH_SIGNATURE_METHOD}%26oauth_timestamp%3D${TIMESTAMP}%26oauth_version%3D${OAUTH_VERSION}"
    echo "Base: $BASE_STRING"
    # https://stackoverflow.com/questions/7285059/hmac-sha1-in-bash
    local SIGNATURE=$(escape $(openssl dgst -binary -sha1 -hmac "${API_SECRET}&" <<< "$BASE_STRING" | base64) )
    # Only single-escape of callback here
    local URL="${API_REQUEST_TOKEN}?oauth_callback=$(escape "$API_REQUEST_TOKEN_CALLBACK")&oauth_consumer_key=${API_KEY}&oauth_nonce=${NONCE}&oauth_signature=${SIGNATURE}%3D&oauth_signature_method=${OAUTH_SIGNATURE_METHOD}&oauth_timestamp=${TIMESTAMP}&oauth_version=${OAUTH_VERSION}"
    echo "$URL"
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
request_token
