<#
//-----------------------------------------------------------------------

//     Copyright (c) {charbelnemnom.com}. All rights reserved.

//-----------------------------------------------------------------------

 .SYNOPSIS
Create backup policy for Hyper-V virtual machine(s).

.DESCRIPTION
Create backup policy to backup Hyper-V virtual machine(s) every day at 5p.m.

.NOTES
File Name : New-WSVMBackup.ps1
Author    : Charbel Nemnom
Version   : 2.0
Date      : 12-December-2016
Requires  : PowerShell Version 3.0 or above
OS        : Windows Server 2012, 2012 R2, 2016 (Full and Server Core)

.LINK
To provide feedback or for further assistance please visit:
https://charbelnemnom.com

.EXAMPLE
./New-WSVMBackup -HVHost <Hyper-V Host Name> -BackupType <Disk, Volume, Network> -WBSchedule "17:00"
This example will set the policy to back up Hyper-V virtual machine(s)
to Disk, Volume or Network Share every day at 5.00 pm.
#>

[CmdletBinding()]
param (
	[Parameter(Mandatory=$true, Position=0, HelpMessage = 'Specify Hyper-V Host')]
	[Alias('Host')]
	[String]$HVHost,

    [Parameter(Mandatory=$true, HelpMessage = 'Specify Backup Destination Type', ParameterSetName = "Enable")]
	[ValidateSet("Disk", "Volume", "Network")]
    [String]$BackupType,

    [Parameter(Mandatory=$true, HelpMessage = 'Specify Backup Schedule')]
	[Alias('Schedule')]
    [String]$WBSchedule
    	  
)

# Check Windows Server Backup Feature
$WSB = Get-WindowsFeature -Name Windows-Server-Backup
If ($WSB.Installed -eq $false) {
    Write-Warning -Message "Windows Server Backup Feature is not installed"
    Write-Verbose "Installing Windows Server Backup..." -Verbose
    Install-WindowsFeature -Name Windows-Server-Backup -IncludeAllSubFeature -Restart:$false
    }

# Check Hyper-V Host
Try {
    Get-VMHost -ComputerName $HVHost -ErrorAction Stop    
    }
Catch
    {
    Write-Error -Message "Hyper-V Host Name: $HVHost is not reachable"
    return
    }

# Select one or more VMs to Backup
$VMs = Get-VM -ComputerName $HVHost | Out-GridView -Title "Select one or more VMs to Backup" -PassThru

# Remove Existing Backup Policy
Try {
     Write-Verbose "Remove existing policy..."
     Remove-WBPolicy -all -force
    }
Catch
    {
     Write-Verbose "No existing policy to remove..."
    }
 
# Create an empty WB Policy Object
Write-Verbose "Create an empty WB Policy Object"            
$WBPolicy = New-WBPolicy
 
# Add Virtual Machine to WB Policy
foreach ($VM in $VMs)
{
Write-Verbose "Add Virtual Machine: $($VM.Name) to WB Policy"
Get-WBVirtualMachine | Where-Object VMName -eq $VM.Name | Add-WBVirtualMachine -Policy $WBPolicy -WarningAction SilentlyContinue
}

# Specify Backup Destination and Define Backup Target
If ($BackupType -eq "Volume")
    {
    $Volume = Read-Host "`nEnter Volume Name i.e. E"
    Try {
         Write-Verbose "Create target volume"
         $TargetVol = New-WBBackupTarget -VolumePath $Volume
        }
    Catch
        {
        Write-Error -Message "Failed to create target volume $Volume"
        return
        }
    }

If ($BackupType -eq "Disk")
   {
   $Disk = Read-Host "`nEnter Disk Name i.e. Seagate"
   $Disks = Get-WBDisk | Where-Object {$_.DiskName -like "*$Disk*"}
   Try  {
         Write-Verbose "Create target disk"
         $TargetVol = New-WBBackupTarget -Disk $Disks
        }
    Catch
        {
        Write-Error -Message "Failed to create target disk $Disk"
        return
        }  
    }

If ($BackupType -eq "Network")
   {
   Write-Verbose "Enter network share credential"
   $Network = Read-Host "`nEnter Network Share i.e. \\server.fqdn\backup"
   Try  {        
        $Cred = Get-Credential -Message "Enter Network Share Credential:" -ErrorAction Stop
        }
   Catch 
       {
        Write-Error -Message "Missing mandatory network Credential"
        return
       } 
   Try  {
        Write-Verbose "Create network share"
        $TargetVol = New-WBBackupTarget -NetworkPath $Network -Credential $Cred -NonInheritAcl:$false
        }
    Catch
        {
        Write-Error -Message "Failed to create target network share $Network"
        return
        } 
    } 

# Add Backup Target
Write-Verbose "Add Backup TargeDiskt" 
Add-WBBackupTarget -Policy $WBPolicy -Target $TargetVol -WarningAction SilentlyContinue
 
# Set a schedule
Write-Verbose "Set Schedule"
Set-WBSchedule -Policy $WBPolicy $WBSchedule
 
# Start the backup
Write-Verbose "Start Backup"
Set-WBPolicy -Policy $WBPolicy -Confirm:$false
Start-WBBackup -Policy $WBPolicy