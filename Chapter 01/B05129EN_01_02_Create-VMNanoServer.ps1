# Create Virtual Machine on Nano Server Hyper-V Host
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - November 29, 2016
# Version 3.0

#region Variables

$NanoSRV = 'NANOSRV-HV01'
$Cred = Get-Credential "Demo\SuperBook"
$Session = New-PSSession -ComputerName $NanoSRV -Credential $Cred
$CimSesion = New-CimSession -ComputerName $NanoSRV -Credential $Cred
$VMTemplatePath = 'C:\Temp'
$vSwitch = 'Ext_vSwitch'
$VMName = 'DemoVM-0'

#endregion


Get-ChildItem -path $VMTemplatePath -filter *.VHDX -recurse | `
Copy-Item -Destination D:\ -ToSession $Session 

1..2 | % {

New-VM -CimSession $CimSesion -Name $VMName$_ -VHDPath "D:\$VMName$_.vhdx" -MemoryStartupBytes 512MB `
-SwitchName $vSwitch -Generation 2

Start-VM -CimSession $CimSesion -VMName $VMName$_ -Passthru    
 
}