Function Sync-Directories {
<#
.SYNOPSIS
    Synchronises a list of folders based on file hashes
.DESCRIPTION
    Synchronises a list of folders based on file hashes
.PARAMETER SourceFolder
    Path to source folder to base synchronisation
.PARAMETER FolderModifier
    String(s) to append to SourceFolder if only certain subfolders are desired
.PARAMETER DestinationFolder
    Path to destination folder
.PARAMETER HashAlgorithm
    Hash Algorithm to use for file comparison (default is MD5)
    Available options are SHA1, SHA256, SHA384, SHA512, MACTripleDES, MD5, and RIPEMD160
.PARAMETER NoRepair
    Should any missing/different files be corrected
.NOTES
    Name: Sync-Directories
    Author: David Bell
    DateCreated: 21/05/2015
.EXAMPLE
    Sync-Directories -SourceFolder "\\server\share\" -FolderModifier "subfolder1","subfolder2" -DestinationFolder "\\server2\share"
#>

    [CmdletBinding(
    )]

    Param(
        [parameter(Mandatory=$True)] [STRING]$SourceFolder,
        [STRING[]]$FolderModifier,
        [parameter(Mandatory=$True)] [STRING]$DestinationFolder,
        [STRING]$HashAlgorithm = "md5",
        [SWITCH]$NoRepair
    )

    $folderSourceArray = @()
    $filesSourceArray = @()
    $files = @()
    $filesHash = @()
    $failedFiles = @()
    $persistentfailedFiles = @()

    # build list of folders using FolderModifier
    if($FolderModifier.Count -ne 0)
    {
        $startTime = [System.Diagnostics.Stopwatch]::StartNew()
        for ($i = 0; $i -lt $FolderModifier.Count; $i++)
        {
            Write-Progress -Activity "Building list of folders from FolderModifier" -CurrentOperation $FolderModifier[$i] -PercentComplete (($i+1)/$FolderModifier.Count * 100) -SecondsRemaining (($startTime.Elapsed.TotalSeconds)/($i+1)*($FolderModifier.Count - $i))
            $folderSourceArray += $SourceFolder + "\" + $FolderModifier[$i]
        }
        Write-Progress -Activity "Building list of folders from FolderModifier" -Completed
    } else {
        $folderSourceArray += $SourceFolder
    }

    # Generate list of files
    $startTime = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i = 0; $i -lt $folderSourceArray.Count; $i++)
    {
        Write-Progress -Activity "Generating list of files" -CurrentOperation $folderSourceArray[$i] -PercentComplete ($i/$folderSourceArray.Count*100) -SecondsRemaining (($startTime.Elapsed.TotalSeconds)/($i+1)*($folderSourceArray.Count - $i))
        $files += Get-ChildItem -Path $folderSourceArray[$i] -Recurse
    }
    Write-Progress -Activity "Generating list of files" -Completed

    # Generate hashes of files at Source
    $startTime = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i = 0; $i -lt $files.Count; $i++)
    {
        $fileRelativePath = $files[$i].FullName -replace [regex]::Escape($SourceFolder)
        Write-Progress -Activity "Generating file hashes" -CurrentOperation $fileRelativePath -PercentComplete ($i/$files.Count*100) -SecondsRemaining (($startTime.Elapsed.TotalSeconds)/($i+1)*($files.Count - $i))
        $filesHash += $files[$i] | Select-Object FullName,@{Label='Hash'; Expression={(Get-FileHash -Algorithm $HashAlgorithm $PSItem.FullName).hash}},@{Label='RelativePath'; Expression={$fileRelativePath}}
    }
    Write-Progress -Activity "Generating file hashes" -Completed
    
    # Test each file at DestinationFolder
    $startTime = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i = 0; $i -lt $files.Count; $i++)
    {
        Write-Progress -Activity "Testing files at destination" -CurrentOperation $filesHash[$i].RelativePath -PercentComplete ($i/$filesHash.Count*100) -SecondsRemaining (($startTime.Elapsed.TotalSeconds)/($i+1)*($filesHash.Count - $i))
        if (Test-Path $($DestinationFolder + $filesHash[$i].RelativePath))
        {
            if ($filesHash[$i].Hash -eq (Get-FileHash -Algorithm $HashAlgorithm -Path $($DestinationFolder + $filesHash[$i].RelativePath)).Hash)
            {
                # do nothing, files match
            } else {
                $failedFiles += $filesHash[$i]
            }
        } else {
            $failedFiles += $filesHash[$i]
        }
    }
    Write-Progress -Activity "Testing files at destination" -Completed

    $statusString = "Finished checking files: $($files.Count - $failedFiles.Count)/$($files.Count) ({0:P2})" -f $(($files.Count - $failedFiles.Count)/$files.Count)
    Write-Host $statusString
    
    # If the NoRepair flag is present, stop here
    if ($NoRepair.IsPresent)
    {
        return
    }

    # Begin repairing missing/different files (but only if there are missing/different files!)
    if ($failedFiles.Count -gt 0)
    {
        # Copy the files to the destination
        $startTime = [System.Diagnostics.Stopwatch]::StartNew()
        for ($i = 0; $i -lt $failedFiles.Count; $i++)
        {
            Write-Progress -Activity "Copying failed files" -CurrentOperation $failedFiles[$i].RelativePath -PercentComplete ($i/$failedFiles.Count*100) -SecondsRemaining(($startTime.Elapsed.TotalSeconds)/($i+1)*($failedFiles.Count - $i))
            Copy-Item -Path $failedFiles[$i].FullName -Destination $($DestinationFolder + $failedFiles[$i].RelativePath)
        }
        Write-Progress -Activity "Copying failed files" -Completed

        # Test the failed files at the destination
        $startTime = [System.Diagnostics.Stopwatch]::StartNew()
        for ($i = 0; $i -lt $failedFiles.Count; $i++)
        {
            Write-Progress -Activity "Testing failed files" -CurrentOperation $failedFiles[$i].RelativePath -PercentComplete ($i/$failedFiles.Count*100) -SecondsRemaining(($startTime.Elapsed.TotalSeconds)/($i+1)*($failedFiles.Count - $i))
            if (Test-Path $($DestinationFolder + $failedFiles[$i].RelativePath))
            {
                if ($failedFiles[$i].Hash -eq (Get-FileHash -Algorithm $HashAlgorithm -Path $($DestinationFolder + $failedFiles[$i].RelativePath)).Hash)
                {
                    # do nothing, files match
                } else {
                    $persistentfailedFiles += $failedFiles[$i]
                }
            } else {
                $persistentfailedFiles += $failedFiles[$i]
            }
        }
        Write-Progress -Activity "Testing failed files" -Completed
        $statusString = "Finished checking failed files: $($failedFiles.Count - $persistentfailedFiles.Count)/$($failedFiles.Count) ({0:P2})" -f $(($failedFiles.Count - $persistentfailedFiles.Count)/$failedFiles.Count)
        Write-Host $statusString
    }
}
