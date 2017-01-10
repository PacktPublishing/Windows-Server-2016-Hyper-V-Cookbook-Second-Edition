# Discrete Device Assignment (DDA)
# Windows Server 2016 Hyper-V
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - December 04, 2016
# Version 1.0

$VM = “WS-DC”
#Turn off VM
Stop-VM –Name $VM
#Set automatic stop action for the VM to Turn off
Set-VM –Name $VM -AutomaticStopAction TurnOff
#Enable Write-combining on the CPU
Set-VM -GuestControlledCacheTypes $true –VMName $VM 
#Configure 32 bit MMIO space
Set-VM –LowMemoryMappedIoSpace 3Gb –VMName $VM
#Configure Greater than 32 bit MMIO space 
Set-VM –HighMemoryMappedIoSpace 33280Mb –VMName $VM

#Use Get-PnpDevice command with a search condition to narrow down the PnpDdevice class
#In this example we are searching for "Display" class and NVIDIA GPU
$pnpdevs = Get-PnpDevice  -PresentOnly | Where-Object {$_.Class -eq "Display"} | Where-Object {$_.FriendlyName -match "NVIDIA"}
$pnpdevs | ft -AutoSize

#Disable the GPU graphic device on the host system by using the Disable-PnpDevice
Disable-PnpDevice -InstanceId $pnpdevs.InstanceId -Confirm:$false

#Specify the location path for the GPU card
$locationPath = (Get-PnpDeviceProperty -KeyName DEVPKEY_Device_LocationPaths -InstanceId $pnpdevs.InstanceId).Data[0]

#Dismount the device as a Display adapter from the host
Dismount-VMHostAssignableDevice –force –LocationPath $locationPath 

#Assign the device to the guest VM
Add-VMAssignableDevice –LocationPath $locationPath –VMName $VM
#Turn on VM
Start-VM –Name $VM


###Remove a GPU from the VM and return it back to the host###

#Turn off VM that’s currently using DDA
Stop-VM –Name $VM

#Get the locationpath for the dismounted display adapter
$DisMountedDevice = Get-PnpDevice -PresentOnly | Where-Object {$_.Class -eq "Display"} | Where-Object {$_.FriendlyName -match "NVIDIA"}
$DisMountedDevice | ft -AutoSize

$LocationPathOfDismDDA = ($DisMountedDevice | Get-PnpDeviceProperty DEVPKEY_Device_LocationPaths).data[0]
$LocationPathOfDismDDA

#Remove the display adapter from the VM
Remove-VMAssignableDevice -LocationPath $LocationPathOfDismDDA -VMName $VM

#Mount the display adapter again to the host
Mount-VmHostAssignableDevice -locationpath $LocationPathOfDismDDA

#Enable the GPU graphic device on the host system by using the Enable-PnpDevice
Enable-PnpDevice -InstanceId $pnpdevs.InstanceId -Confirm:$false

#Set the memory resources on the VM for the GPU to the defaults
Set-VM -GuestControlledCacheTypes $False -LowMemoryMappedIoSpace 256MB -HighMemoryMappedIoSpace 512MB -VMName $VM

#Start the VM
Start-VM -Name $VM