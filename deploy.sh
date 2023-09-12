#!/bin/bash

# Define the server and path
SERVER="server"
SERVER_IP="172.16.82.147:2222"  # Replace with actual IP if it changes
TARGET_PATH="/home/vagrant"

# Copy backup.sh to server
vagrant scp packup.sh server:$TARGET_PATH

# Run backup.sh on server with all arguments passed to runon.sh
vagrant ssh server -c "bash ${TARGET_PATH}/packup.sh $@"


