#!/bin/bash

# Variables
CLIENT1_IP="172.16.82.148"
CLIENT2_IP="172.16.82.149"
SSH_KEY_PATH="/home/vagrant/.ssh/id_rsa"

# Generate SSH key if it doesn't exist
if [ ! -f "$SSH_KEY_PATH" ]; then
    ssh-keygen -t rsa -f "$SSH_KEY_PATH" -N ""
fi

# Function to copy SSH key to a client
copy_ssh_key() {
    local CLIENT_IP="$1"
    
    # Add the client's SSH key to known hosts to avoid authenticity prompt
    ssh-keyscan "$CLIENT_IP" >> ~/.ssh/known_hosts

    # Copy the SSH key to the client
    ssh-copy-id -i "$SSH_KEY_PATH.pub" vagrant@"$CLIENT_IP"
}

# Copy SSH keys to clients
copy_ssh_key "$CLIENT1_IP"
copy_ssh_key "$CLIENT2_IP"
