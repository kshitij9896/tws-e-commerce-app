#!/bin/bash

# Prevent interactive prompts from blocking the installation
export DEBIAN_FRONTEND=noninteractive

# Update system and install core packages
sudo apt-get update -y
sudo apt-get install -y fontconfig openjdk-21-jre wget apt-transport-https gnupg lsb-release snapd

# 1. Corrected & Updated Jenkins Installation
sudo mkdir -p /usr/share/keyrings
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# Single-line repository entry to prevent formatting breaks
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

# Ensure Jenkins service starts up cleanly
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins

# 2. Docker installation & User configuration
sudo apt-get install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker

# Explicitly add both root, jenkins, and the default ubuntu user to docker groups
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins
sudo usermod -aG docker root

# 3. Trivy Security Scanner Installation (Updated Key Management)
sudo mkdir -p /etc/apt/keyrings
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /etc/apt/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update -y
sudo apt-get install trivy -y

# 4. Snap Utilities (AWS CLI, Helm, Kubectl)
sudo snap install aws-cli --classic
sudo snap install helm --classic
sudo snap install kubectl --classic

# Final service restart to finalize permissions
sudo systemctl restart docker
sudo systemctl restart jenkins