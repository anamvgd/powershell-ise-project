function Show-Menu {
   param (
        [string]$Title = 'Admin Data Center'
    )
 $selection = Read-Host "`n Please select an option: `n 
              1. Display top 5 processes with most memory consummtion `n
              2. Show filesystems which have used more than 60% of its capacity `n
              3. Display the 5 biggest files of a specified type in a specific folder `n
              4. Create file registro.txt for saving date, free ram and used swap `n
              5. Display entries with least free ram and with most used swap from registro.txt`n"

 switch ($selection)
 {
     '1' {
         DisplayTableId
     } '2' {
         DeployFilesystems
     } '3' {
         $folder = Read-Host "Please enter a folder route"
         $type = Read-Host "Please write a file type" 
            
         SpecificFolderFile -folder $folder -type $type
     } '4' {
         MemoryFile
     } '5' {
         GetInfoFile
     }
 }
 }

function DisplayTableId {

    Get-Process -IncludeUserName | 
    Sort-Object -Property VM -Descending | 
    Select-Object -First 5 | 
    Format-Table -Property Username, Id, @{name = "MemoryPercentage"; expression = 
        {(Get-WMIObject Win32_PhysicalMemory | 
            Measure -Property capacity -Sum | %{$_.sum/1Mb})/[int]($_.VM/1mb)}
        }

}

function DeployFilesystems {
    
    Get-WmiObject Win32_Volume | 
        where-object -FilterScript {$_.FreeSpace/$_.Capacity -lt 0.4} | 
        Format-Table  Capacity, FreeSpace, @{name = "MountPoint"; expression = {$_.Name}}

}

function SpecificFolderFile {
  
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [alias('folder')]
        [string] $filelocation
        ,
        [parameter(Mandatory = $true)]
        [alias('type')]
        [string] $filetype
    )

    Get-ChildItem -Path $folder | 
    Where-Object -FilterScript {$_.Extension -like $type} |
    Sort-Object -Property Length -Descending |
    Select-Object -First 5

 }

function MemoryFile {

    if(Test-Path -Path "$HOME/registro.txt") {
        Get-WmiObject Win32_OperatingSystem | 
        Format-Table @{name="date"; expression={Get-Date}}, @{name="free_ram"; expression={$_.FreePhysicalMemory}}, 
        @{L="used_swap";E={($_.totalvirtualmemorysize - $_.freevirtualmemory)*1KB/1GB}} -HideTableHeaders |
        Out-File -FilePath "$HOME/registro.txt" -Append
    } else {
        Get-WmiObject Win32_OperatingSystem | 
        Format-Table @{name="date"; expression={Get-Date}}, @{name="free_ram"; expression={$_.FreePhysicalMemory}}, 
        @{L="used_swap";E={($_.totalvirtualmemorysize - $_.freevirtualmemory)*1KB/1GB}} |
        Out-File -FilePath "$HOME/registro.txt"
    }

}

function GetInfoFile {

    Get-Content -Path "$HOME/registro.txt" -AsByteStream -Raw |
    Get-Member -InputObject $bytearray
   

}

Show-Menu



