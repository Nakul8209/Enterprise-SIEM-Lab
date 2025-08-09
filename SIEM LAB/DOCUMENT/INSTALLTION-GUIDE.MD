# Installation Guide: Enterprise SIEM Lab Setup

**File**: `docs/installation-guide.md`

This comprehensive guide provides step-by-step instructions for deploying a complete SIEM laboratory environment with Wazuh and Sysmon based on real-world implementation experience.

## 📋 Prerequisites

### System Requirements
- **Ubuntu Server**: 20.04 LTS or 22.04 LTS (minimum 4GB RAM, 50GB storage)
- **Windows Endpoint**: Windows 10/11 (physical or virtual machine)
- **Network**: Both systems must communicate on TCP port 1514 and 1515
- **Administrator Access**: Required on both Ubuntu and Windows systems
- **Internet Connection**: Required for package downloads and updates

### Tools Required
- **PowerShell** (Windows) - Run as Administrator
- **Terminal/SSH access** (Ubuntu)
- **Web browser** for dashboard access
- **Text editor** for configuration files

***

## 🚀 Quick Installation (Recommended)

For users who want to get started quickly, use the automated Wazuh installation script:

### Ubuntu Wazuh Server (Automated)
```bash
# Download and run automated installation script
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

This single command installs all Wazuh components and provides login credentials automatically[1].

***

## 🐧 Phase 1: Manual Ubuntu Wazuh Server Installation

### Step 1: System Preparation
```bash
# Update the system packages
sudo apt update && sudo apt upgrade -y

# Install required dependencies
sudo apt install curl apt-transport-https unzip wget libcap2-bin software-properties-common gnupg lsb-release -y

# Reboot if kernel updates were installed
sudo reboot
```

### Step 2: Add Wazuh Repository
```bash
# Import Wazuh GPG key
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor | sudo tee /usr/share/keyrings/wazuh-archive-keyring.gpg > /dev/null

# Add Wazuh repository to sources list
echo "deb [signed-by=/usr/share/keyrings/wazuh-archive-keyring.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list

# Update package database
sudo apt update
```

### Step 3: Install Wazuh Manager
```bash
# Install Wazuh Manager (main server component)
sudo apt install wazuh-manager -y

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable wazuh-manager
sudo systemctl start wazuh-manager

# Verify installation
sudo systemctl status wazuh-manager
```

**Expected Output**: Service should show `active (running)` status[2].

### Step 4: Install Wazuh Indexer
```bash
# Install the indexer for log storage and search capabilities
sudo apt install wazuh-indexer -y

# Enable and start indexer service
sudo systemctl enable wazuh-indexer
sudo systemctl start wazuh-indexer

# Verify indexer is running
sudo systemctl status wazuh-indexer
```

### Step 5: Install Wazuh Dashboard
```bash
# Install the web dashboard interface
sudo apt install wazuh-dashboard -y

# Enable and start dashboard service
sudo systemctl enable wazuh-dashboard
sudo systemctl start wazuh-dashboard

# Verify dashboard is running
sudo systemctl status wazuh-dashboard
```

### Step 6: Configure Firewall Rules
```bash
# Configure UFW firewall for Wazuh communication
sudo ufw allow 1514/tcp    # Agent communication
sudo ufw allow 1515/tcp    # Agent enrollment
sudo ufw allow 55000/tcp   # Wazuh API
sudo ufw allow 9200/tcp    # Wazuh indexer
sudo ufw allow 443/tcp     # Dashboard HTTPS access

# Enable firewall if not already enabled
sudo ufw enable

# Check firewall status
sudo ufw status numbered
```

### Step 7: Access Wazuh Dashboard
```bash
# Get your server IP address
ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1
```

1. Open web browser and navigate to: `https://YOUR-UBUNTU-IP`
2. Accept the self-signed certificate warning
3. Login with default credentials:
   - **Username**: `admin`
   - **Password**: `admin`
4. **Critical**: Change default password immediately after first login

### Step 8: Verify Server Installation
```bash
# Check all Wazuh services status
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard

# Verify manager is listening for agent connections
sudo netstat -tlnp | grep 1514

# Monitor manager logs for any issues
sudo tail -f /var/ossec/logs/ossec.log
```

***

## 🪟 Phase 2: Windows Sysmon Installation

### Step 1: Download Sysmon Components
Open **PowerShell as Administrator** and execute:

```powershell
# Create dedicated Sysmon directory
New-Item -Path "C:\Sysmon" -ItemType Directory -Force
Set-Location "C:\Sysmon"

# Download latest Sysmon from Microsoft Sysinternals
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "Sysmon.zip"

# Extract Sysmon files
Expand-Archive -Path "Sysmon.zip" -DestinationPath "." -Force
Remove-Item "Sysmon.zip"

# Verify Sysmon executable is present
Get-ChildItem "C:\Sysmon" -Filter "*.exe"
```

### Step 2: Download Enhanced Configuration
```powershell
# Download SwiftOnSecurity enhanced configuration (industry standard)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "sysmonconfig.xml"

# Verify configuration file downloaded successfully
Test-Path "C:\Sysmon\sysmonconfig.xml"
```

### Step 3: Install Sysmon with Enhanced Configuration
```powershell
# Install Sysmon with comprehensive logging configuration
# Use Sysmon64.exe for 64-bit systems, Sysmon.exe for 32-bit systems
.\Sysmon64.exe -accepteula -i sysmonconfig.xml

# Verify Sysmon service installation
Get-Service Sysmon64

# Configure service to start automatically on boot
Set-Service -Name Sysmon64 -StartupType Automatic
```

**Expected Output**: Service should show `Running` status[3].

### Step 4: Validate Sysmon Functionality
```powershell
# Check recent Sysmon events in Event Viewer
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10 | Format-Table TimeCreated, Id, LevelDisplayName -AutoSize

# Generate test activities to verify logging
Write-Host "Generating test events..." -ForegroundColor Yellow
notepad.exe
Start-Sleep -Seconds 3
Stop-Process -Name "notepad" -Force -ErrorAction SilentlyContinue

# Verify process creation events (Event ID 1)
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterXPath "*[System[EventID=1]]" -MaxEvents 5 | Select-Object TimeCreated, Message
```

### Step 5: Verify Event Categories
Check that Sysmon is capturing comprehensive event types:

```powershell
# Display available Sysmon event types
$SysmonEvents = @{
    1 = "Process Creation"
    3 = "Network Connection"
    11 = "File Creation"
    12 = "Registry Object Added/Deleted"
    13 = "Registry Value Set"
    8 = "CreateRemoteThread"
}

Write-Host "Sysmon Event Categories Configured:" -ForegroundColor Green
$SysmonEvents.GetEnumerator() | Sort-Object Key | ForEach-Object {
    Write-Host "Event ID $($_.Key): $($_.Value)" -ForegroundColor Cyan
}
```

***

## 🔗 Phase 3: Wazuh Agent Deployment

### Step 1: Generate Agent Installation Command

1. **Access Wazuh Dashboard**: Navigate to `https://YOUR-UBUNTU-IP`
2. **Navigate to Agents**: Go to **Agents** → **Deploy new agent**
3. **Configure Agent Settings**:
   - **Server address**: Your Ubuntu server IP address
   - **Agent name**: Descriptive name (e.g., `WindowsLaptop-01`)
   - **Agent group**: `default` or create custom group
4. **Copy PowerShell Command**: Copy the generated installation command

### Step 2: Install Wazuh Agent on Windows

Execute the generated command in **PowerShell as Administrator**:

```powershell
# Example installation command (use your generated version):
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.3-1.msi -OutFile wazuh-agent.msi; msiexec.exe /i wazuh-agent.msi /q WAZUH_MANAGER='YOUR-UBUNTU-IP' WAZUH_AGENT_NAME='WindowsLaptop-01'

# Start the Wazuh agent service
NET START WazuhSvc

# Verify agent service is running
Get-Service WazuhSvc | Select-Object Name, Status, StartType
```

### Step 3: Verify Agent Configuration
```powershell
# Check agent configuration file
$ConfigPath = "C:\Program Files (x86)\ossec-agent\ossec.conf"
if (Test-Path $ConfigPath) {
    Get-Content $ConfigPath | Select-String -Pattern "server"
} else {
    Write-Host "Configuration file not found at $ConfigPath" -ForegroundColor Red
}

# Check recent agent logs
$LogPath = "C:\Program Files (x86)\ossec-agent\logs\ossec.log"
if (Test-Path $LogPath) {
    Get-Content $LogPath | Select-Object -Last 15
} else {
    Write-Host "Log file not found at $LogPath" -ForegroundColor Red
}
```

### Step 4: Test Network Connectivity
```powershell
# Test connection to Wazuh server on agent communication port
$ServerIP = "YOUR-UBUNTU-IP"  # Replace with actual server IP
$TestResult = Test-NetConnection -ComputerName $ServerIP -Port 1514

if ($TestResult.TcpTestSucceeded) {
    Write-Host "✅ Agent can communicate with Wazuh server on port 1514" -ForegroundColor Green
} else {
    Write-Host "❌ Cannot connect to Wazuh server. Check firewall and network settings" -ForegroundColor Red
}
```

### Step 5: Verify Agent Connection in Dashboard

**On Ubuntu Server:**
```bash
# Check connected agents
sudo /var/ossec/bin/agent_control -l

# Monitor agent connection logs
sudo tail -f /var/ossec/logs/ossec.log | grep -i agent
```

**In Wazuh Web Dashboard:**
1. Navigate to **Agents** section
2. Verify your Windows agent appears with **Active** status
3. Click on agent name to view detailed information
4. Check **Security Events** tab for incoming Sysmon data

***

## 🔍 Phase 4: Validation and Testing

### Comprehensive System Verification

**1. Dashboard Accessibility Test:**
```bash
# On Ubuntu server, check dashboard is responding
curl -k -I https://localhost
```

**2. Agent Communication Test:**
```powershell
# On Windows, generate test events and verify they appear in dashboard
ping google.com
Invoke-WebRequest -Uri "https://www.example.com" -UseBasicParsing
New-Item -Path "$env:TEMP\wazuh-test.txt" -ItemType File -Value "Test file for Wazuh monitoring"
```

**3. Event Flow Verification:**
- Navigate to dashboard **Discover** section
- Filter by your agent name
- Look for Sysmon events (rule IDs 61xxx series)
- Verify events include process details, network connections, and file operations

### Performance Validation
```bash
# Check system resource usage
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard
free -h
df -h

# Monitor active connections
sudo netstat -tlnp | grep -E "(1514|1515|9200|443)"
```

***

## ⚡ Troubleshooting Common Issues

### Issue 1: Dashboard Inaccessible
**Symptoms**: Browser cannot reach `https://YOUR-IP`

**Solutions**:
```bash
# Check dashboard service
sudo systemctl status wazuh-dashboard

# Verify port binding
sudo netstat -tlnp | grep 443

# Check firewall rules
sudo ufw status

# Restart dashboard if needed
sudo systemctl restart wazuh-dashboard
```

### Issue 2: Agent Connection Failures
**Symptoms**: Agent shows "Disconnected" in dashboard

**Solutions**:
```powershell
# Test network connectivity
Test-NetConnection -ComputerName SERVER-IP -Port 1514

# Check agent service
Get-Service WazuhSvc

# Restart agent service
NET STOP WazuhSvc
NET START WazuhSvc

# Check agent logs for errors
Get-Content "C:\Program Files (x86)\ossec-agent\logs\ossec.log" | Select-Object -Last 20
```

### Issue 3: Missing Sysmon Events
**Symptoms**: Agent connected but no Sysmon data in dashboard

**Solutions**:
```powershell
# Verify Sysmon service is running
Get-Service Sysmon64

# Check Sysmon events locally
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 10

# Restart both services
Restart-Service Sysmon64
NET STOP WazuhSvc
NET START WazuhSvc
```

***

## 🎯 Post-Installation Security Configuration

### Change Default Credentials
```bash
# Generate secure password
openssl rand -base64 32

# Update admin password using Wazuh API
curl -k -X PUT "https://localhost:55000/security/users/1" \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type: application/json" \
-d '{"password":"NEW_SECURE_PASSWORD"}'
```

### Configure SSL/TLS Certificates
```bash
# Generate custom certificates for production use
sudo /usr/share/wazuh-indexer/plugins/opensearch-security/tools/install_demo_configuration.sh -y
```

### Enable Log Rotation
```bash
# Configure log rotation to prevent disk space issues
sudo nano /etc/logrotate.d/wazuh-logs
```

***

## 📋 Installation Checklist

- [ ] Ubuntu Wazuh server installed and accessible via HTTPS
- [ ] All Wazuh services running (manager, indexer, dashboard)
- [ ] Firewall configured with appropriate rules
- [ ] Sysmon installed on Windows with enhanced configuration
- [ ] Sysmon service running and generating events
- [ ] Wazuh agent installed and service running
- [ ] Agent appears as "Active" in dashboard
- [ ] Sysmon events flowing to dashboard in real-time
- [ ] Test events generating and appearing within seconds
- [ ] Default credentials changed to secure passwords
- [ ] Network connectivity verified between all components

***

## 🚀 Next Steps

After successful installation:

1. **Explore Security Events**: Navigate through the dashboard to understand event categories
2. **Create Custom Rules**: Develop detection rules for specific threat scenarios  
3. **Configure Alerting**: Set up email or webhook notifications for critical events
4. **Performance Tuning**: Optimize settings for your environment's log volume
5. **Backup Configuration**: Save your configuration files and certificates

***

## 📚 Additional Resources

- **Official Documentation**: [Wazuh Installation Guide][2]
- **Sysmon Configuration**: [SwiftOnSecurity Config Repository](https://github.com/SwiftOnSecurity/sysmon-config)
- **Community Support**: [Wazuh Community Forums](https://wazuh.com/community/)
- **Advanced Configuration**: See `architecture.md` and `troubleshooting.md` in this repository

***

**Installation complete! Your enterprise SIEM lab is ready for advanced threat detection and security monitoring.**