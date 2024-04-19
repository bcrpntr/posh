# Using environment variables
$gMSA_AccountName = $env:gMSA_AccountName  # Environment variable for the gMSA account name
$npcapInstallerPath = $env:npcapInstallerPath  # Environment variable for the NPCAP installer path
$sensorInstallerPath = $env:sensorInstallerPath  # Environment variable for the MDI sensor installer path
$accessKey = $env:accessKey  # Environment variable for MDI sensor access key

# Ensure running with Administrative rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "This script must be run as an Administrator."
    exit 1
}

# Import Active Directory module
try {
    Import-Module ActiveDirectory
} catch {
    Write-Output "Error importing Active Directory module. Ensure it is installed and you have the necessary permissions."
    exit 1
}

# Function to install and configure the gMSA on the server
function Install-gMSA {
    param([string]$gMSAName)
    Install-ADServiceAccount -Identity $gMSAName
    if ($?) {
        Write-Output "gMSA $gMSAName installed successfully."
    } else {
        Write-Output "Failed to install gMSA $gMSAName."
        exit 1
    }
}

# Function to install NPCAP
function Install-NPCAP {
    if (-not (Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE 'Npcap%'")) {
        Start-Process -FilePath $npcapInstallerPath -ArgumentList '/S' -NoNewWindow -Wait
        Write-Output "NPCAP installed."
    } else {
        Write-Output "NPCAP already installed."
    }
}

# Function to install MDI Sensor
function Install-MDISensor {
    Start-Process -FilePath $sensorInstallerPath -ArgumentList "/quiet NetFrameworkCommandLineArguments='/q' AccessKey=$accessKey" -NoNewWindow -Wait
    Write-Output "MDI Sensor installed."
}

# Main Execution Block
Install-gMSA -gMSAName $gMSA_AccountName
Install-NPCAP
Install-MDISensor

# Check MDI Sensor Service status
$sensorService = Get-Service -Name "Azure Advanced Threat Protection Sensor" -ErrorAction SilentlyContinue
if ($sensorService.Status -eq 'Running') {
    Write-Output "MDI Sensor service is running."
} else {
    Write-Output "MDI Sensor service installation failed or service not started."
    exit 1
}
