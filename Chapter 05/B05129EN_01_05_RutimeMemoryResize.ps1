# Runtime Memory Resize
# Windows Server 2016 Hyper-V
# Author - Charbel Nemnom
# https://charbelnemnom.com
# Date - December 02, 2016
# Version 1.0

$VMs = Get-VM * | Where-Object {$_.DynamicMemoryEnabled -eq $false}

Foreach ($VM in $VMs) {
# Memory Demand Before
$VMMemory = Get-VM -Name $VM.Name | `
        Select Name, State,@{Label="CPU Usage %";Expression={$_.CPUUsage}}, `
        @{Label="Assigned Memory MB";Expression={$_.MemoryAssigned/1048576}}, `
        @{Label="Memory Demand MB";Expression={$_.MemoryDemand/1048576}}, MemoryStatus

Write-Output "Current Memory Demand" $VMMemory

If ($VMMemory.'Memory Demand MB' -gt $VMMemory.'Assigned Memory MB') {
   [int64]$RAM = 1MB*($VMMemory.'Assigned Memory MB'+$VMMemory.'Memory Demand MB'+1)
   Set-VM -Name $VMName -MemoryStartupBytes $RAM

   # Memory Demand After
    $VMMemory = Get-VM -Name $VM.Name | `
        Select Name, State,@{Label="CPU Usage %";Expression={$_.CPUUsage}}, `
        @{Label="Assigned Memory MB";Expression={$_.MemoryAssigned/1048576}}, `
        @{Label="Memory Demand MB";Expression={$_.MemoryDemand/1048576}}, MemoryStatus

    Write-Output "Updated Memory Demand" $VMMemory
    }

}