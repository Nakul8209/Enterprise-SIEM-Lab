# Simple Sysmon Installation Script - What you actually used
# Run as Administrator

# Create directory and navigate
New-Item -Path "C:\Sysmon" -ItemType Directory -Force
Set-Location "C:\Sysmon"

# Download Sysmon
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "Sysmon.zip"

# Extract files
Expand-Archive -Path "Sysmon.zip" -DestinationPath "." -Force
Remove-Item "Sysmon.zip"

# Download SwiftOnSecurity configuration
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile "sysmonconfig.xml"

# Install Sysmon with configuration
.\Sysmon64.exe -accepteula -i sysmonconfig.xml

# Verify installation
Get-Service Sysmon64

# Set to start automatically
Set-Service -Name Sysmon64 -StartupType Automatic

# Check recent events
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 5
