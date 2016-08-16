function Select-Folder($message='Select a folder', $path = 0) { 
    $object = New-Object -comObject Shell.Application  
     
    $folder = $object.BrowseForFolder(0, $message, 0, $path) 
    if ($folder -ne $null) { 
        $folder.self.Path 
    } 
}

#$USBDevices += Get-WmiObject –query “SELECT * from win32_logicaldisk where DriveType = '2'”
$LogicalDisks = Get-WmiObject –query “SELECT * from win32_logicaldisk”
$USBDrives = @()
$SyncTypes = @("Copy All", "Mirror", "Today Copy", "14 Day Copy")

foreach ($device in $LogicalDisks)
{
    if ($device.DriveType -eq '2')
    {
        $USBDrives += $device
    }
}

if ($USBDrives.Count -eq 0)
{
    Write-Host "No USB devices connected"
}
elseif ($USBDrives.Count -eq 1)
{
    Write-Host "Only one device found: $($USBDrives.Name)\, $($USBDrives.VolumeName)"
    $USBDrive = $USBDrives
}
else
{
    "Please select which USB device you want to configure:"
    for ($i = 0; $i -lt $USBDrives.Count; $i++)
    {
        Write-Host "Option $($i+1): $($USBDrives[$i].Name)\, $($USBDrives[$i].VolumeName)"
    }
    $USBDrive = $USBDrives[$(Read-Host -Prompt "Select a device")-1]
}

if ($USBDrive.Count -eq 1)
{
    $syncFolders = @()

    Write-Host "Please setup folders/files you would like to sync to your device"
    do
    {
        # Get the source of the sync
        $source = Select-Folder -message "Choose a source folder"
        # Get the destination of the sync and remove the start
        $destination = (Select-Folder -message "Choose a destination folder" -path $USBDrive.Name).Remove(0,2)
        # Get the sync type
        $type = $SyncTypes | Out-GridView -Title "Select a sync type" -OutputMode Single

        if ((Read-Host -Prompt "You wish to sync ($source) to ($($USBDrive.Name)$destination), is that correct (y/n)") -eq "y")
        {
            if ($source.EndsWith("\"))
            {
                $source = "$source."
            }

            $syncFolders += @{
                Source = $source
                Destination = $destination
                Type = $type
            }
        }
        Write-Host "You have the following file syncs configured:"
        if($syncFolders.Count -eq 1)
        {
            $syncFolders
        }
        else
        {
            $syncFolders | Format-Table -Property Destination, Source, Type
        }
    }
    while ((Read-Host -Prompt "`nDo you wish to add another sync? (Y to continue)") -eq "y")
    
    $json = ConvertTo-Json -InputObject $syncFolders
    Out-File -FilePath "$($USBDrive.name)\IronKey-Sync.json" -InputObject $json
}
else
{
    "Please try again with a USB Drive connected"
}
