<#
//-----------------------------------------------------------------------

//     Copyright (c) {charbelnemnom.com}. All rights reserved.

//-----------------------------------------------------------------------

 .SYNOPSIS
Request a new certificate.

.DESCRIPTION
Request a new certificate from the host that will be used as a member of Hyper-V Replica.

.NOTES
File Name : Get-Certificate.ps1
Author    : Charbel Nemnom
Version   : 1.0
Date      : 18-June-2016
Requires  : PowerShell Version 3.0 or above
OS        : Windows Server 2012, 2012 R2, 2016 (Full and Server Core)

.LINK
To provide feedback or for further assistance please visit:
https://charbelnemnom.com
#>

# Run this script on a domain member management server

# Enter your target Hyper-V Host (FQDN)
$HVHost = 'HVHost01.demo.local', 'HVHost02.demo.local', 'HVHost03.demo.local' 
$Credentials = Get-Credential -Credential "Demo\Admin"

# Enable CredSSP on the client
Enable-PSRemoting -Force
Enable-WSManCredSSP -Role Client -DelegateComputer "*.demo.local" -Force
restart-Service winrm

# Enable CredSSP on the host
Invoke-Command -computername $HVHost -ScriptBlock {
    Enable-PSRemoting -Force
    Enable-WSManCredSSP -Role Server -Force
    Set-Item WSMan:\localhost\Client\TrustedHosts -value "*.demo.local" -Force
    restart-Service winrm
}
 
# Request a new certificate from the host that will be used as member of the Hyper-V Replica
Invoke-Command -computername $HVHost -ScriptBlock {
  Get-Certificate -Template Hyper-VReplicaTemplate -Url ldap:///CN=Ent-Root-CA -CertStoreLocation Cert:\LocalMachine\My -DnsName HVHost01.Demo.Local -Verbose 
} -Credential $Credentials -Authentication Credssp

# For security’s sake, Reset the CredSSP environment to the way it was originally
Disable-WSManCredSSP –Role Client
Invoke-Command –ComputerName $HVHost –ScriptBlock { Disable-WSManCredSSP –Role Server }

# Enable Hyper-V Replica HTTPS Listener
Invoke-Command -computername $HVHost -ScriptBlock {
Enable-Netfirewallrule -displayname "Hyper-V Replica HTTPS Listener (TCP-In)"
}