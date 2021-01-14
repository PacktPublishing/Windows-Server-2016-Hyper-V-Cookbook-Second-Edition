# Windows Server 2016 Hyper V Cookbook Second Edition
This is the code repository for [Windows Server 2016 Hyper V Cookbook Second Edition](https://www.packtpub.com/virtualization-and-cloud/windows-server-2016-hyper-v-cookbook-second-edition?utm_source=github&utm_campaign=9781785884313&utm_medium=repository
), published by Packt. It contains all the supporting project files necessary to work through the book from start to finish.

##Instructions and Navigation

The code included with this book is meant for use as an aid in performing the exercises and should not be used as a replacement for the book itself.
Used out of context, the code may result in an unusable configuration and no warranty is given.

The code will look like the following:
```
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


```
