#!/bin/bash
# Deploy prototype to IONOS
# Usage: ./deploy.sh <folder_name>

# IONOS credentials
SERVER="access993872858.webspace-data.io"
USER="u115257687"
PORT="22"
REMOTE_PATH="/homepages/1/d993872858/htdocs/prototypes"

# Check argument
if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <folder_name>"
    echo "Example: ./deploy.sh site_1"
    exit 1
fi

SITE="$1"

if [ ! -d "$SITE" ]; then
    echo "Error: Directory '$SITE' not found"
    exit 1
fi

echo "Deploying $SITE to IONOS..."

# Using rsync (only uploads changes)
rsync -avz --progress -e "ssh -p $PORT" \
    "./$SITE/" \
    "$USER@$SERVER:$REMOTE_PATH/$SITE/"

echo ""
echo "Done! Site live at:"
echo "https://proto.efehnconsulting.com/$SITE/"
