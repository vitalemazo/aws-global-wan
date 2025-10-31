#!/bin/bash
# User data script for test EC2 instances
# Configures basic tools for connectivity testing

# Update system
yum update -y

# Install useful networking tools
yum install -y \
  tcpdump \
  nmap-ncat \
  bind-utils \
  traceroute \
  wget \
  curl \
  jq

# Set hostname
hostnamectl set-hostname ${vpc_name}-test

# Create info file
cat > /root/instance-info.txt <<EOF
Instance Information
===================
VPC Name: ${vpc_name}
Segment: ${segment_name}
Region: ${region}
Deployed: $(date)

Connectivity Testing Commands:
==============================
# Ping shared services (example: 192.168.1.10)
ping -c 4 192.168.1.10

# Ping other segment (example: 10.10.1.10)
ping -c 4 10.10.1.10

# Test internet connectivity
curl -s https://api.ipify.org
ping -c 4 8.8.8.8

# View Cloud WAN routes
ip route

# Test DNS
nslookup amazon.com
EOF

# Create a simple web server for testing (listens on port 8080)
cat > /root/test-server.sh <<'SCRIPT'
#!/bin/bash
while true; do
  echo -e "HTTP/1.1 200 OK\n\n${vpc_name} - $(hostname -I) - $(date)" | nc -l -p 8080
done
SCRIPT

chmod +x /root/test-server.sh

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log
