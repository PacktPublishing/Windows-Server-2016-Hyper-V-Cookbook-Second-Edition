# Build Windows Server 2016 Nano Server Image
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - November 29, 2016
# Version 3.0

#region Generate Nano Server image with Hyper-V Server role installed
#region Variables

$ComputerName = 'NANOSRV-HV01'
$StagingPath = 'C:\Temp' # Staging path for new image
$ServerISO = 'C:\Temp\WindowsServer2016.ISO' # Path to Windows Server 2016 ISO file
# Mount the ISO Image
Mount-DiskImage $ServerISO
# Get the Drive Letter of the disk ISO image
$DVDDriveLetter = (Get-DiskImage $ServerISO | Get-Volume).DriveLetter 
$MediaPath = ($DVDDriveLetter + ':\')
$DomainName = $env:USERDNSDOMAIN.ToLower()
$Path = Join-Path -Path $StagingPath -ChildPath NanoServer
$Password = Read-Host -Prompt Password -AsSecureString

#endregion Variables

#region Copy source files
if (-not (Test-Path $StagingPath)) {
mkdir $StagingPath
}

$NanoServerSourcePath = Join-Path -Path $MediaPath -ChildPath NanoServer -Resolve
Copy-Item -Path $NanoServerSourcePath -Destination $StagingPath -Recurse -Force

#endregion

#region Generate Nano Hyper-V image
Import-Module -Name (Join-Path -Path $Path -ChildPath NanoServerImageGenerator\NanoServerImageGenerator.psm1) -Verbose

$NanoServerImageParameters = @{

ComputerName = $ComputerName
DeploymentType = 'host'
Edition = 'Datacenter'
MediaPath = $MediaPath
BasePath = (Join-Path -Path $Path -ChildPath $ComputerName)
TargetPath = Join-Path -Path $Path -ChildPath ($ComputerName + '.vhd')
DomainName = $DomainName
AdministratorPassword = $Password
Ipv4Address = '172.16.20.120' 
Ipv4SubnetMask = '255.255.255.0' 
Ipv4Gateway = '172.16.20.1' 
Ipv4Dns = '172.16.20.9'
InterfaceNameOrIndex = 'Ethernet' 
Language = 'en-us'
Compute = $true
Packages = 'Microsoft-NanoServer-Compute-Package'
EnableRemoteManagementPort = $true
OEMDrivers = $true
Clustering = $true
EnableEMS = $true
}

New-NanoServerImage @NanoServerImageParameters

#endregion

# Dismount Windows Server 2016 ISO Image
Dismount-DiskImage $ServerISO

#endregion