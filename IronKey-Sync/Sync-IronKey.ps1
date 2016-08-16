<#
.SYNOPSIS
    Synchronises files to a USB drive
.DESCRIPTION
    Periodically synchronises files from preconfigured sources onto set destinations on a USB device
.PARAMETER Frequency
    Length of time (in seconds) between syncs. Default 600 seconds.
.PARAMETER IronKeyUsersGroup
    String containing the CN of the group for all IronKey users. Default is IronKey Users.
.PARAMETER requiredUserGroups
    Array of CNs of groups of users who must have their IronKey continuously up to date.
.PARAMETER MaxRetry
    Number of retries between notifications to the user that the copy has failed. Default is 3.
.NOTES
    Name: Sync-IronKey
    Author: David Bell
    DateCreated: 2/12/2015
.EXAMPLE
Sync-Ironkey -Frequency 1200
#>
param(
    [int]$Frequency = 600,
    [string]$IronKeyUsersGroup = "CN=IronKeyUsers,CN=Users,DC=domain,DC=com",
    [string[]]$requiredUserGroups = @("CN=Business Unit,CN=Users,DC=domain,DC=com"),
    [int]$MaxRetry = 3
)

$retryCount = 0
$retry = $true
$UserCN = whoami /fqdn

$IsIronKeyUser = ([ADSI]"LDAP://$IronKeyUsersGroup").IsMember("LDAP://$UserCN")
$IsRequiredGroupUser = $false
foreach ($group in $requiredUserGroups)
{
    if (([ADSI]"LDAP://$group").IsMember("LDAP://$UserCN"))
    {
        $IsRequiredGroupUser = $true
    }
}

while ($IsIronKeyUser) {
    $LogicalDisks = Get-WmiObject –query “SELECT * from win32_logicaldisk”
    $USBDrives = @()
    $syncSuccessful = $false

    foreach ($device in $LogicalDisks)
    {
        if ($device.DriveType -eq '2')
        {
            $USBDrives += $device
        }
    }

    if ($USBDrives.Count -eq 0)
    {
        # if there are no USB devices we can't do anything
        Write-Host "No USB devices connected"
        $retryCount++
    }
    else
    {
        # If there are multiple USB Drives we need to check each of them for syncing
        $ConfigFound = $false
        foreach ($USBDrive in $USBDrives)
        {
            # Check if the sync json file exists
            if(Test-Path -Path "$($USBDrive.name)\IronKey-Sync.json")
            {
                $ConfigFound = $true
                # Read the json file in to an object so we can use it
                $syncFolders = (Get-Content -Path "$($USBDrive.name)\IronKey-Sync.json") -join "`n" | ConvertFrom-Json

                # iterate through each folder pair
                foreach ($folder in $syncFolders)
                {
                    $Destination = "$($USBDrive.DeviceID)$($folder.Destination)"
                    # Check the type of sync, doing this as a string is nasty but probably the easiest
                    if ($folder.Type -eq "Mirror")
                    {
                        robocopy $folder.Source $Destination /mir /mt
                        $syncSuccessful = $true
                    }
                    else
                    {
                        # Implement some kind of exception to throw when we don't know the copy type, this could be important if people are running different versions/break the config
                        "Unimplemented copy type"
                    }
                }
            }
        }

        if (-not $ConfigFound)
        {
            $retryCount++
        }
    }

    if (-not $syncSuccessful -and $retryCount -ge $MaxRetry -and $IsRequiredGroupUser)
    {
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup("IronKey sync appears to have failed. Check that you have your IronKey plugged in and unlocked and that you can see the files you are attempting to copy. If all else fails, contact IT", 0,"IronKey Sync Failed",16)
    }

    # Sleep for some time before checking again
    Start-Sleep -Seconds $Frequency
}
