<#
.SYNOPSIS
    Creates a Hashtable containing the Applocker rules from an XML file created using Powershell
.DESCRIPTION
    Creates a Hashtable with the Applocker rules from an XML file.
.PARAMETER path
    Path to XML file to open
.NOTES
    Name: Load-ApplockerRuleSet
    Author: David Bell
    DateCreated: 16/11/2015
.EXAMPLE
    Load-ApplockerRuleSet.ps1 -path c:\temp\applocker.xml
#>

param (
    [Parameter(Mandatory=$True)][string]$path
)

[xml]$xmlRules = Get-Content $path

$dllHashes = @()
$exeHashes = @()
$trustedDLLPublishers = @()
$trustedEXEPublishers = @()

foreach ($ruleCollection in $xmlRules.AppLockerPolicy.RuleCollection)
{
    if($ruleCollection.Type -eq "dll")
    {
        foreach ($fileHashRule in $ruleCollection.FileHashRule)
        {
            foreach ($fileHash in $fileHashRule.Conditions.FileHashCondition.FileHash)
            {
                $fHash = @{
                    SourceFileName = $fileHash.SourceFileName
                    Type = $fileHash.Type
                    Data = $fileHash.Data
                    SourceFileLength = $fileHash.SourceFileLength
                }
                $dllHashes += $fHash
            }
        }

        foreach ($filePublisherRule in $ruleCollection.FilePublisherRule)
        {
            $fPublisher = @{
                PublisherName = $filePublisherRule.Conditions.FilePublisherCondition.PublisherName
            }
            $trustedDLLPublishers += $fPublisher
        }
    }
    elseif ($ruleCollection.Type -eq "exe")
    {
        foreach ($fileHashRule in $ruleCollection.FileHashRule)
        {
            foreach ($fileHash in $fileHashRule.Conditions.FileHashCondition.FileHash)
            {
                $fHash = @{
                    SourceFileName = $fileHash.SourceFileName
                    Type = $fileHash.Type
                    Data = $fileHash.Data
                    SourceFileLength = $fileHash.SourceFileLength
                }
                $exeHashes += $fHash
            }
        }

        foreach ($filePublisherRule in $ruleCollection.FilePublisherRule)
        {
            $fPublisher = @{
                PublisherName = $filePublisherRule.Conditions.FilePublisherCondition.PublisherName
            }
            $trustedEXEPublishers += $fPublisher
        }
    }
}

$ruleSet = @{
    dllHashes = $dllHashes
    exeHashes = $exeHashes
    trustedDLLPublishers = $trustedDLLPublishers
    trustedEXEPublisher = $trustedEXEPublishers
}

$ruleSet
# SIG # Begin signature block
# MIIH4QYJKoZIhvcNAQcCoIIH0jCCB84CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6iFTROl/K89usIm/RZkyL9i4
# 2cigggWQMIIFjDCCBO6gAwIBAgITGgAAAGDuqPRJRbwxxQAAAAAAYDAKBggqhkjO
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
# L6HG0FTOayZ4Rjl2yfplthtdbuSacfzgJ+BT3V8KpEQ7I5L2OVgxggG7MIIBtwIB
# ATCBkjB7MRIwEAYKCZImiZPyLGQBGRYCYXUxEzARBgoJkiaJk/IsZAEZFgNnb3Yx
# EzARBgoJkiaJk/IsZAEZFgN2aWMxFzAVBgoJkiaJk/IsZAEZFgd0Y3ZsYW4xMSIw
# IAYDVQQDExlUQ1YgQ2VydGlmaWNhdGUgQXV0aG9yaXR5AhMaAAAAYO6o9ElFvDHF
# AAAAAABgMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkG
# CSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEE
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTu5MRKeaIS4VyD21hXOYacNEEhaTALBgcq
# hkjOPQIBBQAEgYowgYcCQRKbpu/RrmB/6DzHJUyePqbYrr9i6XnI5mZXRWzaRbM5
# 0nEZVrOPg+X23UykPLXm/slah2by9Ikedwgatre0JZihAkIBaep8bkQiBrF9ABPU
# OSYu0OzqCCuc10I6GjXHS41MYyXYXuz/gmaNYkfnfEOe7crVGMXp9XH9D4BCRv7m
# qZkS0Ck=
# SIG # End signature block
