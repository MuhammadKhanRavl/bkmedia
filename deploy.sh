#!/bin/bash

# Define the server and path
SERVER="server"
SERVER_IP="172.16.82.147"
TARGET_PATH="/home/vagrant"

# Copy packup.sh to server
vagrant scp packup.sh server:$TARGET_PATH

# Run packup.sh on server
vagrant ssh server -c "bash ${TARGET_PATH}/packup.sh $1 $2 $3 $4 $5"

