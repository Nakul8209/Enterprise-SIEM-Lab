# Simple Wazuh Agent Installation - What you actually used
# Run as Administrator
# Replace YOUR-UBUNTU-IP with your actual server IP

# Generated from Wazuh Dashboard:
# 1. Go to Agents -> Deploy new agent
# 2. Select Windows
# 3. Enter server IP and agent name
# 4. Copy the generated command below:

# Example installation command (use your generated version):
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.3-1.msi -OutFile wazuh-agent.msi; msiexec.exe /i wazuh-agent.msi /q WAZUH_MANAGER='YOUR-UBUNTU-IP' WAZUH_AGENT_NAME='WindowsLaptop'

# Start the service
NET START WazuhSvc

# Check service status
Get-Service WazuhSvc

# Test connectivity
Test-NetConnection -ComputerName YOUR-UBUNTU-IP -Port 1514

# Check agent logs
Get-Content "C:\Program Files (x86)\ossec-agent\logs\ossec.log" | Select-Object -Last 10
