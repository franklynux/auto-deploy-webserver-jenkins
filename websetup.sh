#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Update package list and install Apache, Wget, and Unzip
apt-get update
apt-get install -y apache2 wget unzip

# Set the ServerName directive to avoid FQDN error
echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Download the website template
wget https://www.tooplate.com/zip-templates/2137_barista_cafe.zip

# Unzip the template into the Apache default directory
unzip 2137_barista_cafe.zip -d /var/www/html/

# Move the webapp files into the Apache default directory
mv /var/www/html/2137_barista_cafe/* /var/www/html/

# Clean up by removing the downloaded zip file
rm 2137_barista_cafe.zip

# Ensure proper ownership of the web files
chown -R www-data:www-data /var/www/html/

# Restart Apache to apply changes
service apache2 restart
