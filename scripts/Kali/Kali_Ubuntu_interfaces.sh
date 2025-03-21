#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root or use sudo."
    exit 1
fi

# Detect if the system is Kali Linux or Ubuntu
OS=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

# Prompt for network interface
read -p "Enter network interface (e.g., eth0, wlan0, ens33): " IFACE

# Prompt for new IP address
read -p "Enter new IP address: " IPADDR

# Prompt for new netmask
read -p "Enter new netmask (e.g., 255.255.255.0): " NETMASK

# Prompt for gateway 
read -p "Enter gateway (Blank if not needed): " GATEWAY

# Prompt for DNS
read -p "Enter DNS server (Blank if not needed):" DNS

# Check the OS and modify the corresponding network configuration file
if [[ "$OS" == "kali" || "$OS" == "debian" ]]; then
    CONFIG_FILE="/etc/network/interfaces"

    # Backup existing config
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

#Flush IPs
ip addr flush dev $IFACE

    # Write the new configuration
    cat > "$CONFIG_FILE" <<EOL
auto lo
iface lo inet loopback

auto $IFACE
iface $IFACE inet static
    address $IPADDR
    netmask $NETMASK
EOL

if [ -n "$GATEWAY" ]; then
    echo "    gateway $GATEWAY" >> /etc/network/interfaces
fi

#If DNS specified
if [ -n "$DNS" ]; then
    echo "    dns-nameservers $DNS" >> /etc/network/interfaces
fi

    # Restart networking service
    systemctl restart networking.service

    echo "Network settings updated for Kali/Debian and made persistent!"

elif [[ "$OS" == "ubuntu" ]]; then
    CONFIG_FILE="/etc/netplan/01-network-manager-all.yaml"

    # Backup existing config
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

#Flush IPs
ip addr flush dev $IFACE

    # Write the new Netplan configuration
    cat > "$CONFIG_FILE" <<EOL
network:
  version: 2
  renderer: NetworkManager 
  ethernets:
    $IFACE:
      addresses:
        - $IPADDR/24
EOL

if [ -n "$GATEWAY" ]; then
    cat <<EOF >> /etc/netplan/01-network-manager-all.yaml
      gateway4: $GATEWAY
EOF
fi

#If DNS specified
if [ -n "$DNS" ]; then
    cat <<EOF >> /etc/netplan/01-network-manager-all.yaml
      nameservers:
        addresses:
          - $DNS
EOF
fi

    # Apply Netplan changes
    netplan apply

    echo "Network settings updated for Ubuntu and made persistent!"
else
    echo "Unsupported OS detected: $OS"
    exit 1
fi
