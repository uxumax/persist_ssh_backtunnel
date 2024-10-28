# SSH Reverse Tunnel Persistence

Bash script that creates a persistent SSH reverse tunnel from your local machine to a public server. It uses a systemd service to keep the tunnel active and auto-restarts if it fails, making sure your connection is always up.

## Script Usage

### Manual Mode

When running the `make_tun.sh` without specifying a host from the SSH config, you will be prompted to enter the necessary parameters manually.

The `make_tun.sh` asks for the following parameters:

1. **Public server IP** (required)  
   The IP address or hostname of the server with a public IP.

2. **Public server User** (optional, default: `user`)  
   The username for SSH login to the public server.

3. **Public server SSH port** (optional, default: `22`)  
   The port number for the SSH service on the public server.

4. **Public server SSH key path** (optional, default: `~/.ssh/id_rsa`)  
   The path to the private SSH key used for authentication.

5. **Public server forwarding port** (required)  
   The port number on the public server to forward the local service.

6. **Local receiving port** (optional, default: `22`)  
   The port number on the local machine that receives the forwarded traffic.

7. **Local Service name** (optional, default: `backtun-{SERVER_IP}.service`)  
   The `systemd` service name used to manage the tunnel.

### SSH Config Mode

When specifying a host from the SSH config as a command-line argument, the make_tun reads the SSH configuration to populate the necessary parameters.

Example usage:
```bash
sudo ./make_tun.sh your_ssh_config_host
```

The `make_tun.sh` uses the following SSH configuration parameters:

1. **Hostname**  
   The IP address or hostname of the server.

2. **User**  
   The username for SSH login.

3. **Port**  
   The port number for the SSH service.

4. **IdentityFile**  
   The path to the private SSH key used for authentication.

## SSH Config Example

Ensure your `~/.ssh/config` file contains entries similar to this:
```
Host exampleHost
  Hostname 192.168.1.1
  User yourUser
  Port 2222
  IdentityFile ~/.ssh/id_rsa
```

## Creating the Systemd Service

The `make_tun.sh` creates a `systemd` service file, configures it to start on boot, and starts the service immediately. The service is designed to keep the SSH reverse tunnel alive and reconnect automatically if the connection drops.

### Controlling the Service

You can manage the tunnel service using `systemctl` with the service name you provided (or the default name).

Start the service:
```bash
sudo systemctl start {service_name}
```

Stop the service:
```bash
sudo systemctl stop {service_name}
```

Enable the service to start on boot:
```bash
sudo systemctl enable {service_name}
```

Disable the service:
```bash
sudo systemctl disable {service_name}
```

Check the status of the service:
```bash
sudo systemctl status {service_name}
```
