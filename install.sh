#!/bin/bash

# Ensure the script is run with sudo or root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or use sudo"
  exit
fi

# Determine the correct username
if [ -n "$SUDO_USER" ]; then
  USERNAME="$SUDO_USER"
else
  USERNAME="root"
fi

# Prompt for the necessary parameters with default values
read -p "Public server IP (required): " SERVER_IP
if [ -z "$SERVER_IP" ]; then
  echo "Public server IP is required."
  exit 1
fi

read -p "Public server User [user]: " SERVER_USER
SERVER_USER=${SERVER_USER:-user}

read -p "Public server SSH port [22]: " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-22}

read -p "Public server SSH key path [$HOME/.ssh/id_rsa]: " SSH_KEY_PATH
SSH_KEY_PATH=${SSH_KEY_PATH:-$HOME/.ssh/id_rsa}

if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "SSH key file does not exist at $SSH_KEY_PATH."
  exit 1
fi

# Check if SSH key requires a password
if ssh-keygen -y -f "$SSH_KEY_PATH" >/dev/null 2>&1; then
  echo "SSH key does not require a password."
else
  echo "SSH key requires a password."
  exit 1
fi

# Check if SSH key works and can establish a connection
if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -p "$SERVER_PORT" "$SERVER_USER@$SERVER_IP" exit; then
  echo "SSH key works and connection can be established."
else
  echo "SSH key does not work or cannot establish a connection."
  exit 1
fi

read -p "Public server Port that forwarding to Local SSH port (required): " REMOTE_PORT
if [ -z "$REMOTE_PORT" ]; then
  echo "Public server forwarding to local SSH port is required."
  exit 1
fi

read -p "Local SSH port [22]: " LOCAL_PORT
LOCAL_PORT=${LOCAL_PORT:-22}

read -p "Local Service name ["backtun-$SERVER_IP.service"]: " $LOCAL_SERVICE_NAME
LOCAL_SERVICE_NAME=${LOCAL_SERVICE_NAME:-"backtun-$SERVER_IP.service"}

# Create the systemd service unit file
SERVICE_FILE="/etc/systemd/system/$LOCAL_SERVICE_NAME"

sudo bash -c "cat > $SERVICE_FILE" << EOL
[Unit]
Description=SSH Reverse Tunnel
After=network.target

[Service]
ExecStart=/usr/bin/ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=accept-new -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p $SERVER_PORT -N -R $REMOTE_PORT:localhost:$LOCAL_PORT $SERVER_USER@$SERVER_IP
Restart=always
RestartSec=3
User=$USERNAME

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to recognize the new service, enable it, and start it
sudo systemctl daemon-reload
sudo systemctl enable $LOCAL_SERVICE_NAME
sudo systemctl start $LOCAL_SERVICE_NAME

echo "SSH reverse tunnel systemd service created and started successfully."
echo "You can control this service with systemctl using name $LOCAL_SERVICE_NAME"
