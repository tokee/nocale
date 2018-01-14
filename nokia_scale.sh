#!/bin/bash

#
# Logs in to health.nokia.com and exports the health data
#

###############################################################################
# CONFIG
###############################################################################

pushd ${BASH_SOURCE%/*} > /dev/null
if [[ -s nokia_scale.conf ]]; then
    source nokia_scale.conf
fi

: ${USERID:=""} # Digits
: ${EMAIL:=""}
: ${PASSWORD:=""}

popd > /dev/null

function usage() {
    echo "Usage: ./nokia_scale.sh <`echo \"$VERSIONS\" | sed 's/ / | /g'`>"
    exit $1
}

check_parameters() {
    if [[ -z "$USERID" || -z "$EMAIL" || -z "$PASSWORD" ]]; then
        echo "Error: Please state USERID, EMAIL & PASSWORD"
        usage 2
    fi
}

################################################################################
# FUNCTIONS
################################################################################

# Login by POSTing to
# https://account.health.nokia.com/connectionwou/account_login?r=https%3A%2F%2Fdashboard.health.nokia.com%2F
# with body
# email=te%2Bnokiascale%40ekot.dk&password=**********&is_admin=
# Stores a session cookie in nikia_scale.cookies
login() {
    local LOGIN_URL="https://account.health.nokia.com/connectionwou/account_login?r=https%3A%2F%2Fdashboard.health.nokia.com%2F"
    local BODY=$(sed -e 's/+/%2B/g' -e 's/@/%40/g' <<< "email=${EMAIL}&password=${PASSWORD}&is_admin=")
    #echo "curl> $LOGIN_URL with body $BODY"
    echo "Performing login and saving session cookies to nokia_scale.cookies"
    # https://stackoverflow.com/questions/1324421/how-to-get-past-the-login-page-with-wget
    rm -f nokia_scale.cookies
    curl -v -i -c nokia_scale.cookies -X POST --data "$BODY" "$LOGIN_URL" > nokia_scale.login.last
    echo "*** Cookies start"
    cat nokia_scale.cookies
    echo "*** Cookies end"
}

export_data() {
    local EXPORT_URL="https://account.health.nokia.com/export/my_data"
    curl -v -b nokia_scales.cookies "$EXPORT_URL" > nokia_scale.export_page.log
    exit
    
    local EXPORT_URL="https://account.health.nokia.com/export/my_data?selecteduser=${USERID}"
    echo "Getting download_token for export using $EXPORT_URL"
    #https://account.health.nokia.com/export/my_data?selecteduser=14810361
    curl -v --load-cookies nokia_scales.cookies "$EXPORT_URL" > nokia_scale.export_page.log
    exit
    
    local EXPORT_BODY=""
    echo "Exporting data to nokia_scale.csv"
    curl -b nokia_scale.cookies 
}



# https://www.reddit.com/r/withings/comments/6icxoa/option_to_export_my_data_as_csv_is_now_removed_in/
# Export from https://account.health.nokia.com/export/my_data?selecteduser=14810361
# https://account.health.nokia.com/export/user_select

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
login
export_data
