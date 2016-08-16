Function Mount-Drive {
<#
.SYNOPSIS
    Mounts the newest subfolder in a remote SMB share as a network share to a given drive letter
.DESCRIPTION
    Mounts the newest subfolder in a remote SMB share as a network share to a given drive letter
.PARAMETER RemoteServer
    Hostname or IP address of remote server
.PARAMETER ShareFolder
    Name of the parent share on the remote server
.PARAMETER DriveLetter
    Drive letter to use to mount folder
.PARAMETER Force
    Force remove the drive letter if it is already mounted
.NOTES
    Name: Mount-Drive
    Author: David Bell
    DateCreated: 2/06/2015
.EXAMPLE
    Mount-Drive -RemoteServer file-server-01 -ShareFolder folder-01
#>

    Param(
        [parameter(Mandatory=$True)] [STRING]$RemoteServer,
        [parameter(Mandatory=$True)] [STRING]$ShareFolder,
        [parameter(Mandatory=$True)] [STRING]$DriveLetter,
        [SWITCH]$Force
    )

    # Test that the remote host is available
    if(-not $(Test-Connection -ComputerName $RemoteServer -Count 3 -Quiet))
    {
        "Unable to connect to host"
        exit 1
    }

    # Setup the network com object
    $net = $(New-Object -ComObject WScript.Network);

    # Get the folder we wish to mount
    $FullSharePath = $(Get-ChildItem -Path "\\$RemoteServer\$ShareFolder" -Directory | Sort-Object -Property Name | Select-Object -Last 1).FullName
    
    # Check if there is an existing drive mounted and remove it
    if ($net.EnumNetworkDrives() -match "${DriveLetter}:")
    {
        if ($Force.IsPresent)
        {
            $net.RemoveNetworkDrive("${DriveLetter}:", $True)
        } else {
            "Drive letter $DriveLetter already exists"
            exit 1
        }
    }

    $net.MapNetworkDrive("${DriveLetter}:","$FullSharePath")
    exit 0
}
