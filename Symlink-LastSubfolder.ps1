<#
.SYNOPSIS
    Creates a Symlink to the newest subfolder within a file share
.DESCRIPTION
    Useful for selecting the most recent backup which you wish to offline to tape
.PARAMETER RemoteServer
    The remote SMB server
.PARAMETER ShareFolder
    The share and folder path on the RemoteServer
.PARAMETER MountLocation
    The location you with the mount the symlink on the local host
.PARAMETER Force
    Will delete an existing symlink at the MountLocation if found
.NOTES
    Name: Symlink-LastSubfolder
    Author: David Bell
    DateCreated: 3/06/2015
    
    We used this to grab the most recent backup from our NetGear ReadyDATA when backing up to tape with Symantec Backup Exec.
    Setup a pretask to run the PowerShell script to create the symlink and a post task to remove the symlink to make sure everything it tidy again (e.g. cmd /c rmdir c:\temp\symlink-backupjobname)
.EXAMPLE
    Symlink-LastSubfolder.ps1 -RemoteServer sernamedns -ShareFolder BACKUPJOBNAME\Completed_Backups -MountLocation C:\temp\symlink-backupjobname
#>
Param(
  [string]$RemoteServer,
  [string]$ShareFolder,
  [string]$MountLocation,
  [switch]$Force
)

# Test that the remote host is available
if(-not $(Test-Connection -ComputerName $RemoteServer -Count 3 -Quiet))
{
    "Unable to connect to host"
    exit 1
}

# Get the folder we wish to mount
$FullSharePath = $(Get-ChildItem -Path "\\$RemoteServer\$ShareFolder" -Directory | Sort-Object -Property Name | Select-Object -Last 1).FullName
    
# Check if there is an symlink and remove it
if (Test-Path -Path $MountLocation -PathType Container)
{
    if ($Force.IsPresent)
    {
        cmd /c rmdir $MountLocation
    } else {
        "$MountLocation already exists"
        exit 1
    }
}

cmd /c mklink /d $MountLocation $FullSharePath
exit 0
