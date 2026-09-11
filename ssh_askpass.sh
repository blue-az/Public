#!/usr/bin/env bash
# Prompt for the deploy password. Target comes from deploy.env (gitignored)
# so this file carries no account details.
here="$(cd "$(dirname "$0")" && pwd)"
[[ -f "$here/deploy.env" ]] && source "$here/deploy.env"
zenity --password --title="IONOS Deploy" \
       --text="Password for ${IONOS_USER:-deploy}@${IONOS_HOST:-the deploy host}"
