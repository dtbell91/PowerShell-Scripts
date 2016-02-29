<#
.SYNOPSIS
    Generates Applocker rules for all applicable files within certain directory
.DESCRIPTION
    Recursively searches for Applocker controlled file types within a given directory and generates required file hashes and lists of trusted publishers.
    Returns an Applocker rule hashtable
.PARAMETER path
    Path to recursively search for Applocker controlled files
.PARAMETER exeFileTypes
    Array containing Executable file types (already includes known default types: *.exe)
.PARAMETER dllFileTypes
    Array containing DLL file types (already includes known default types: *.dll, *.ocx, and the undocumented *.pyd)
.NOTES
    Name: Get-ApplockerRules
    Author: David Bell
    DateCreated: 16/11/2015
.EXAMPLE
    Get-ApplockerRules.ps1 -path "c:\blp"
#>
param (
    [Parameter(Mandatory=$True)][string]$path,
    [array]$exeFileTypes = @('*.exe'),
    [array]$dllFileTypes = @('*.dll','*.ocx','*.pyd','*.xll')
)


# Initialise variables
$files = @()
$filesHash = @()
$dllHashes = @()
$exeHashes = @()
$publishers = @()
$filesPublisher = @()
$trustedDLLPublishers = @()
$trustedEXEPublishers = @()

# Build list of files
$files += Get-ChildItem * -Path $path -File -Force -Recurse -Include $($dllFileTypes+$exeFileTypes)

# Iterate through the files and generate the hash and publisher details for each
$startTime = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt $files.Count; $i++)
{
    Write-Progress -Activity "Generating file info" -CurrentOperation $files[$i] -PercentComplete (($i+1)/$files.Count * 100) -SecondsRemaining (($startTime.Elapsed.TotalSeconds)/($i+1)*($files.Count - $i))
    # Get the Applocker File Info for the file. You must generate the hash this way as it isn't really a SHA256 hash
    $applockerFileInfo = Get-AppLockerFileInformation $files[$i].FullName

    # Check if the file has publisher info, if not just go with the file hash
    if ($applockerFileInfo.Publisher -eq $null)
    {
        $fHash = @{
            SourceFileName = $applockerFileInfo.Hash.SourceFileName
            FullName = $files[$i].FullName
            Type = $applockerFileInfo.Hash.HashType
            Data = $applockerFileInfo.Hash.HashDataString
            SourceFileLength = $applockerFileInfo.Hash.SourceFileLength
        }
        $filesHash += $fHash
    }
    # if the file does have publisher info, save that as well as the file hash so that we can choose which to use
    else
    {
        if (-not $publishers.Contains($applockerFileInfo.Publisher.PublisherName))
        {
            $publishers += $applockerFileInfo.Publisher.PublisherName
        }
        $fPublisher = @{
            SourceFileName = $applockerFileInfo.Hash.SourceFileName
            FullName = $files[$i].FullName
            Type = $applockerFileInfo.Hash.HashType
            Data = $applockerFileInfo.Hash.HashDataString
            SourceFileLength = $applockerFileInfo.Hash.SourceFileLength
            PublisherName = $applockerFileInfo.Publisher.PublisherName
        }
        $filesPublisher += $fPublisher
    }
}
Write-Progress -Activity "Generating file info" -Completed

$startTime = [System.Diagnostics.Stopwatch]::StartNew()
# Step through each of the discovered publishers to see if we trust them or only want the file hashes
for ($i = 0; $i -lt $publishers.Count; $i++)
{
    Write-Progress -Activity "Reviewing publishers" -CurrentOperation $publishers[$i] -PercentComplete (($i+1)/$publishers.Count * 100) -SecondsRemaining (($startTime.Elapsed.TotalSeconds)/($i+1)*($publishers.Count - $i))
    $publisherFiles = @()
    
    $hasDLLs = $false
    $hasEXEs = $false

    # Build a prompt as per https://technet.microsoft.com/en-us/library/ff730939.aspx
    $title = "The following files are signed by $($publishers[$i])"
    $message = ""
    foreach ($f in $filesPublisher)
    {
        if ($f.PublisherName -eq $publishers[$i])
        {
            $message += "$($f.FullName)`n"
            $publisherFiles += $f
            if (-not $hasDLLs)
            {
                foreach ($dllType in $dllFileTypes)
                {
                    if ($f.SourceFileName -like $dllType)
                    {
                        $hasDLLs = $true
                        break
                    }
                }
            }
            if (-not $hasEXEs)
            {
                foreach ($exeType in $exeFileTypes)
                {
                    if ($f.SourceFileName -like $exeType)
                    {
                        $hasEXEs = $true
                        break
                    }
                }
            }
        }
    }
    $message += "Which type of rule would you like to apply to these files?"

    $publisherRule = New-Object System.Management.Automation.Host.ChoiceDescription "&Publisher Rule", "Allows all code signed by this publisher to run"
    $hashRule = New-Object System.Management.Automation.Host.ChoiceDescription "&Hash Rule", "Adds all files to the file hash rules, does not make the publisher be trusted"
    $skip = New-Object System.Management.Automation.Host.ChoiceDescription "&Skip", "Either this publisher it already trusted or you do not want these files to be allowed by Applocker"

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($publisherRule,$hashRule,$skip)

    $results = $host.ui.PromptForChoice($title, $message, $options, 0)

    switch ($results)
    {
        0 # Publisher Rule
        {
            if ($hasDLLs)
            {
                $trustedDLLPublishers += @{
                    PublisherName = $publishers[$i]
                }
            }
            if ($hasEXEs)
            {
                $trustedEXEPublishers += @{
                    PublisherName = $publishers[$i]
                }
            }
        }

        1 # Hash Rule
        {
            $filesHash += $publisherFiles
        }

        2 # Skip
        {
            # do nothing
        }
    }
}

# Split the files in DLL and EXE types
$startTime = [System.Diagnostics.Stopwatch]::StartNew()
for ($i = 0; $i -lt $filesHash.Count; $i++)
{
    Write-Progress -Activity "Spliting rules into DLL and EXE" -CurrentOperation $filesHash[$i] -PercentComplete (($i+1)/$filesHash.Count * 100) -SecondsRemaining (($startTime.Elapsed.TotalSeconds)/($i+1)*($filesHash.Count - $i))
    $isDLL = $false
    foreach ($dllType in $dllFileTypes)
    {
        if($filesHash[$i].SourceFileName -like $dllType)
        {
            $matched = $false
            foreach ($r in $dllHashes)
            {
                if (($filesHash[$i].SourceFileName -eq $r.SourceFileName) -and ($filesHash[$i].SourceFileLength -eq $r.SourceFileLength) -and ($filesHash[$i].Type -eq $r.Type) -and ($filesHash[$i].Data -eq $r.Data))
                {
                    $matched = $true
                    break
                }
            }
            if (-not $matched)
            {
                $dllHashes += @{
                    SourceFileName = $filesHash[$i].SourceFileName
                    Type = $filesHash[$i].Type
                    Data = $filesHash[$i].Data
                    SourceFileLength = $filesHash[$i].SourceFileLength
                }
            }
            $isDLL = $true
            break
        }
    }
    if(-not $isDLL)
    {
        foreach ($exeType in $exeFileTypes)
        {
            if($filesHash[$i].SourceFileName -like $exeType)
            {
                $matched = $false
                foreach ($r in $exeHashes)
                {
                    if (($filesHash[$i].SourceFileName -eq $r.SourceFileName) -and ($filesHash[$i].SourceFileLength -eq $r.SourceFileLength) -and ($filesHash[$i].Type -eq $r.Type) -and ($filesHash[$i].Data -eq $r.Data))
                    {
                        $matched = $true
                        break
                    }
                }
                if (-not $matched)
                {
                    $exeHashes += @{
                        SourceFileName = $filesHash[$i].SourceFileName
                        Type = $filesHash[$i].Type
                        Data = $filesHash[$i].Data
                        SourceFileLength = $filesHash[$i].SourceFileLength
                    }
                }
                break
            }
        }
    }
}

$ruleSet = @{
    dllHashes = $dllHashes
    exeHashes = $exeHashes
    trustedDLLPublishers = $trustedDLLPublishers
    trustedEXEPublisher = $trustedEXEPublishers
}

return $ruleSet
# SIG # Begin signature block
# MIIH4gYJKoZIhvcNAQcCoIIH0zCCB88CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbCLACj0a7n5aaFyMTVi44RX+
# ovigggWQMIIFjDCCBO6gAwIBAgITGgAAAGDuqPRJRbwxxQAAAAAAYDAKBggqhkjO
# PQQDBDB7MRIwEAYKCZImiZPyLGQBGRYCYXUxEzARBgoJkiaJk/IsZAEZFgNnb3Yx
# EzARBgoJkiaJk/IsZAEZFgN2aWMxFzAVBgoJkiaJk/IsZAEZFgd0Y3ZsYW4xMSIw
# IAYDVQQDExlUQ1YgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTE1MDgxMzIzMzky
# MVoXDTIwMDgxMTIzMzkyMVowgYUxEjAQBgoJkiaJk/IsZAEZFgJhdTETMBEGCgmS
# JomT8ixkARkWA2dvdjETMBEGCgmSJomT8ixkARkWA3ZpYzEXMBUGCgmSJomT8ixk
# ARkWB3RjdmxhbjExDjAMBgNVBAMTBVVzZXJzMRwwGgYDVQQDExNEYXZpZCBCZWxs
# IFdTIEFkbWluMIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQArytmLroIBQTDCSGy
# 69eOr0F4VtuFsHJ032+4mJ0pffxaK40KBpg9HZFm3+81yWNR5pI3klRNPE9o3QDV
# w/8OX28BiO4WRT8V7UnMwYg8ZtXFHdvVzz3gSrkbGhOWJ6/NCXmxEGhIpNHv4vSg
# thvbXD140VUjfKgFOp4lYLUDVRj93n2jggMBMIIC/TA7BgkrBgEEAYI3FQcELjAs
# BiQrBgEEAYI3FQiHxoEchYPWFJGPM4GfhjbLiFtKgZ3wVobbvyoCAWQCAQcwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwCwYDVR0PBAQDAgeAMBsGCSsGAQQBgjcVCgQOMAww
# CgYIKwYBBQUHAwMwHQYDVR0OBBYEFN/t9Dld23dU9ZZ+A5hgsLRNXHZeMB8GA1Ud
# IwQYMBaAFGs5C6K1Qv6JZ+YRJNFEEURBwEKXMIHqBgNVHR8EgeIwgd8wgdyggdmg
# gdaGgdNsZGFwOi8vL0NOPVRDViUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5LENO
# PXNydnJvb3RjYSxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049
# U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz10Y3ZsYW4xLERDPXZpYyxEQz1n
# b3YsREM9YXU/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENs
# YXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIIBFAYIKwYBBQUHAQEEggEGMIIBAjCB
# yQYIKwYBBQUHMAKGgbxsZGFwOi8vL0NOPVRDViUyMENlcnRpZmljYXRlJTIwQXV0
# aG9yaXR5LENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2
# aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPXRjdmxhbjEsREM9dmljLERDPWdvdixE
# Qz1hdT9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlv
# bkF1dGhvcml0eTA0BggrBgEFBQcwAYYoaHR0cDovL3NydnJvb3RjYS50Y3ZsYW4x
# LnZpYy5nb3YuYXUvb2NzcDA6BgNVHREEMzAxoC8GCisGAQQBgjcUAgOgIQwfZGJl
# bGx3c2FkbWluQHRjdmxhbjEudmljLmdvdi5hdTAKBggqhkjOPQQDBAOBiwAwgYcC
# QSEx5r2cj5hsetFbajVaOyremc5ziv0YIpg0YpmEGLSBs5CAkGp5Sc7iJYtbsnx8
# d8/oBl1bSnVozc3QoHliW7qbAkIAh32p2cHdW+Aik5vNuqAOunOzgEuvDcRxKEs+
# L6HG0FTOayZ4Rjl2yfplthtdbuSacfzgJ+BT3V8KpEQ7I5L2OVgxggG8MIIBuAIB
# ATCBkjB7MRIwEAYKCZImiZPyLGQBGRYCYXUxEzARBgoJkiaJk/IsZAEZFgNnb3Yx
# EzARBgoJkiaJk/IsZAEZFgN2aWMxFzAVBgoJkiaJk/IsZAEZFgd0Y3ZsYW4xMSIw
# IAYDVQQDExlUQ1YgQ2VydGlmaWNhdGUgQXV0aG9yaXR5AhMaAAAAYO6o9ElFvDHF
# AAAAAABgMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkG
# CSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEE
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTVrHxctvv0OVGcR5b5bRKJbVJdUjALBgcq
# hkjOPQIBBQAEgYswgYgCQgDhJKOfnYoJNj7UeHaXCtSIf6JFYZCuwS1DfMyCD8lZ
# 05HJYUdMD+L4eAunBbf6stsswh/+GSI0IXwLbXuUeIzd3wJCATYpP8XLqIZUStBx
# y9xcZWVEMgS5o1pxqDxmuBw+JlvJ987H1zb39nD/sKykYWfnToKx/p0iGH6H4fua
# d6qdtFdS
# SIG # End signature block
