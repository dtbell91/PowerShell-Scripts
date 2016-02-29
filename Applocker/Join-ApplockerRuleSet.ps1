<#
.SYNOPSIS
    Combines two or more Applocker rule hashtables and outputs an XML file
.DESCRIPTION
    Combines two or more Applocker rule hashtables and outputs an XML file
.PARAMETER rulesets
    Array of Applocker ruleset hashtables
.NOTES
    Name: Join-ApplockerRuleSet
    Author: David Bell
    DateCreated: 16/11/2015
.EXAMPLE
    Join-ApplockerRuleSet.ps1 $rulesets
#>

param (
    [Parameter(Mandatory=$True)][array]$rulesets
)

# initialise our empty hash tables
$dllHashes = @()
$exeHashes = @()
$trustedDLLPublishers = @()
$trustedEXEPublishers = @()

# start populating the hash tables
$startTime1 = [System.Diagnostics.Stopwatch]::StartNew()
$count1 = 0
foreach ($set in $rulesets)
{
    Write-Progress -Activity "Iterating through Rulesets" -Id 1 -CurrentOperation "Ruleset $count1 of $($rulesets.Count)" -PercentComplete ($count1/($rulesets.Count))
    $count1++
    
    $startTime2 = [System.Diagnostics.Stopwatch]::StartNew()
    $count2 = 0
    foreach ($rule in $set["dllHashes"])
    {
        Write-Progress -Activity "Removing DLL duplicates" -Id 2 -ParentId 1 -CurrentOperation "Ruleset $count2 of $($set["dllHashes"].Count)" -PercentComplete ($count2/($set["dllHashes"].Count)) -SecondsRemaining (($startTime2.Elapsed.TotalSeconds)/($count2+1)*($set["dllHashes"].Count - $count2))
        $count2++
        $matched = $false
        foreach ($r in $dllHashes)
        {
            if (($rule.SourceFileName -eq $r.SourceFileName) -and ($rule.SourceFileLength -eq $r.SourceFileLength) -and ($rule.Type -eq $r.Type) -and ($rule.Data -eq $r.Data))
            {
                $matched = $true
                break
            }
        }

        if (-not $matched)
        {
            $dllHashes += $rule
        }
    }
    Write-Progress -Activity "Removing DLL duplicates" -Id 2 -Completed

    $startTime2 = [System.Diagnostics.Stopwatch]::StartNew()
    $count2 = 0
    foreach ($rule in $set["exeHashes"])
    {
        Write-Progress -Activity "Removing EXE duplicates" -Id 2 -ParentId 1 -CurrentOperation "Ruleset $count2 of $($set["exeHashes"].Count)" -PercentComplete ($count2/($set["exeHashes"].Count)) -SecondsRemaining (($startTime2.Elapsed.TotalSeconds)/($count2+1)*($set["exeHashes"].Count - $count2))
        $count2++
        $matched = $false
        foreach ($r in $exeHashes)
        {
            if (($rule.SourceFileName -eq $r.SourceFileName) -and ($rule.SourceFileLength -eq $r.SourceFileLength) -and ($rule.Type -eq $r.Type) -and ($rule.Data -eq $r.Data))
            {
                $matched = $true
                break
            }
        }

        if (-not $matched)
        {
            $exeHashes += $rule
        }
    }
    Write-Progress -Activity "Removing EXE duplicates" -Id 2 -Completed

    $startTime2 = [System.Diagnostics.Stopwatch]::StartNew()
    $count2 = 0
    foreach ($rule in $set["trustedDLLPublishers"])
    {
        Write-Progress -Activity "Removing trusted DLL publisher duplicates" -Id 2 -ParentId 1 -CurrentOperation "Ruleset $count2 of $($set["trustedDLLPublishers"].Count)" -PercentComplete ($count2/($set["trustedDLLPublishers"].Count)) -SecondsRemaining (($startTime2.Elapsed.TotalSeconds)/($count2+1)*($set["trustedDLLPublishers"].Count - $count2))
        $count2++
        $matched = $false
        foreach ($r in $trustedDLLPublishers)
        {
            if($rule.PublisherName -eq $r.PublisherName)
            {
                $matched = $true
                break
            }
        }

        if (-not $matched)
        {
            $trustedDLLPublishers += $rule
        }
    }
    Write-Progress -Activity "Removing trusted DLL publisher duplicates" -Id 2 -Completed

    $startTime2 = [System.Diagnostics.Stopwatch]::StartNew()
    $count2 = 0
    foreach ($rule in $set["trustedEXEPublishers"])
    {
        Write-Progress -Activity "Removing trusted EXE publisher duplicates" -Id 2 -ParentId 1 -CurrentOperation "Ruleset $count2 of $($set["trustedEXEPublishers"].Count)" -PercentComplete ($count2/($set["trustedEXEPublishers"].Count)) -SecondsRemaining (($startTime2.Elapsed.TotalSeconds)/($count2+1)*($set["trustedEXEPublishers"].Count - $count2))
        $count2++
        $matched = $false
        foreach ($r in $trustedEXEPublishers)
        {
            if($rule.PublisherName -eq $r.PublisherName)
            {
                $matched = $true
                break
            }
        }

        if (-not $matched)
        {
            $trustedEXEPublishers += $rule
        }
    }
    Write-Progress -Activity "Removing trusted EXE publisher duplicates" -Id 2 -Completed
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2BzOvIoBfiMrbM0NEs6/7J9b
# dgCgggWQMIIFjDCCBO6gAwIBAgITGgAAAGDuqPRJRbwxxQAAAAAAYDAKBggqhkjO
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
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRm1igtdAYcv06BYuAeNxGINQ6G6DALBgcq
# hkjOPQIBBQAEgYswgYgCQgDDeKq3AQmYbi8Up7Yeasn/B11VzRqNpCYrEBxKO9Sx
# 6ThVHuAI3Xm2WbDSV0JO/PfAs29/3fCl7trfcYNM3NBqcQJCAaiWPzOILAGQdOoC
# bIFPBNdwLgTrg7XBPwIsqlRiyROGep+0mscW5dp4Vk3OeAMMR7wNCQpaYKvyJOIW
# hZSLydZf
# SIG # End signature block
