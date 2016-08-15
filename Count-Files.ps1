Function Count-Files {
<#
.SYNOPSIS
    Returns the number of files in a given location which match the provided filter
.DESCRIPTION
        Synchronises a list of folders based on file hashes
.PARAMETER Path
    Path to folder to count files
.PARAMETER Include
    Filter for files to include
.PARAMETER Exclude
    Filter for files to exclude
.PARAMETER Recurse
    Recurse through folders
.NOTES
    Name: Count-Files
    Author: David Bell
    DateCreated: 22/05/2015
.EXAMPLE
    Count-Files -Path "\\servername\share" -Include ".doc" -Exclude ".docx" -Recurse
#>

    [CmdletBinding(
    )]

    Param(
        [parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] [STRING]$Path,
        [parameter(ValueFromPipelineByPropertyName=$true)] [STRING[]]$Include,
        [parameter(ValueFromPipelineByPropertyName=$true)] [STRING[]]$Exclude,
        [SWITCH]$Recurse
    )

    $parms = @{
        Path = $Path;
        Recurse = $Recurse
    }
    Get-ChildItem -Attributes !d @parms
    Get-ChildItem -Attributes !d @parms | Where-Object {$PSItem.Name -like $Include -and $PSItem.Name -notlike $Exclude}
    (Get-ChildItem -Attributes !d @parms | Measure-Object).Count
}
