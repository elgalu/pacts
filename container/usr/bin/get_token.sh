#!/usr/bin/env bash

# This script
# - returns an oauth2 service token

# Container requirements to use this script:
#  RUN apt-get update -qq && apt-get install -qqy jq curl
#  RUN curl -L http://cpanmin.us | perl - App::cpanminus
#  RUN cpanm URI::Escape

# Exit immediately if a command exits with a non-zero status
set -e

urlenc() {
  echo "$(perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$1")"
}

encoded_scopes="uid"

application_username=$(jq -r .application_username /meta/credentials/user.json)
application_password=$(jq -r .application_password /meta/credentials/user.json)
client_id=$(jq -r .client_id /meta/credentials/client.json)
client_secret=$(jq -r .client_secret /meta/credentials/client.json)
encoded_application_password=$(urlenc $application_password)
access_token=$(curl -u "$client_id:$client_secret" --silent -d "grant_type=password&username=$application_username&password=$encoded_application_password&scope=$encoded_scopes" https://auth.example.org/oauth2/access_token\?realm\=/services | jq -r .access_token)

# Return the token without new line
echo -n "$access_token"
