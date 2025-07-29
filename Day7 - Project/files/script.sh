#!/bin/bash

# Update package list
echo "Updating packages..."
sudo apt-get update -y

# Install nginx
echo "Installing nginx..."
sudo apt-get install nginx -y

# Enable and start nginx
echo "Starting nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Create a test HTML page
echo "Creating test HTML page..."
echo "<h1>Welcome to Terraform Provisioned VM</h1>" | sudo tee /var/www/html/index.html

# Print success message
echo "Provisioning complete!"

