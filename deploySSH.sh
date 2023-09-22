#!/bin/bash

# Define the server and path
SERVER="server"
SERVER_IP="172.16.82.147"
TARGET_PATH="/home/vagrant"

# Copy packup.sh to server
vagrant scp setupSSH.sh server:$TARGET_PATH

# Run packup.sh on server
vagrant ssh server -c "bash ${TARGET_PATH}/setupSSH.sh"




