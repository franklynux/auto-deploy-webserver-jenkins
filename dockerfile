FROM ubuntu:20.04

# Set the environment to noninteractive to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && apt-get install -y wget unzip apache2 tzdata

# Copy the setup script
COPY websetup.sh /websetup.sh

# Debug: Check if the script is present and view its contents
RUN ls -la /websetup.sh && cat /websetup.sh

# Make the script executable and run it
RUN chmod +x /websetup.sh && /websetup.sh

# Expose port 80 for web traffic
EXPOSE 80

# Start Apache in the foreground
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
