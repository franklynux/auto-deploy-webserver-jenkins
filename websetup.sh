#!/bin/bash

# Update package list and install Apache, Wget, and Unzip
apt-get update
apt-get install -y apache2 wget unzip

# Download the website template
wget https://www.tooplate.com/zip-templates/2137_barista_cafe.zip

# Unzip the template into the Apache default directory
unzip 2137_barista_cafe.zip -d /var/www/html/

# Clean up by removing the downloaded zip file
rm 2137_barista_cafe.zip

# Ensure proper ownership of the web files
chown -R www-data:www-data /var/www/html/

# Restart Apache to apply changes
service apache2 restart
