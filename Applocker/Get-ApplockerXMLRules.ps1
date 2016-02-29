<#
.SYNOPSIS
    Generates an Applocker rule XML file
.DESCRIPTION
    Turns an Applocker hashtable into an XML file for importing into a group policy object
.PARAMETER ruleset
    Applocker ruleset hashtable
.PARAMETER ruleNames
    Name for Applocker hash rules, name will prefix publisher rules
.PARAMETER outFile
    File to save .xml Applocker rules to
    If absent, XML will be written to the console
.NOTES
    Name: Get-ApplockerRules
    Author: David Bell
    DateCreated: 16/11/2015
.EXAMPLE
    Get-ApplockerXMLRules.ps1 -ruleset $applocker -outFile c:\temp\applocker.xml
#>

param (
    [Parameter(Mandatory=$True)][hashtable]$ruleset,
    [string]$ruleNames = $(Get-Date -Format o | foreach {$_ -replace ":", "."}),
    [string]$outFile
)

$dllHashes = $ruleset["dllHashes"]
$exeHashes = $ruleset["exeHashes"]
$trustedDLLPublishers = $ruleset["trustedDLLPublishers"]
$trustedEXEPublishers = $ruleset["trustedEXEPublishers"]

$XML = '<?xml version="1.0" encoding="utf-8"?>
<AppLockerPolicy Version="1">'
if (($dllHashes.Count -ne 0) -or ($trustedDLLPublishers.Count -ne 0))
{
    $XML += '
    <RuleCollection Type="Dll" EnforcementMode="NotConfigured">'
    if ($dllHashes.Count -ne 0)
    {
        $XML += '
        <FileHashRule Id="'+[System.Guid]::NewGuid().Guid+'" Name="'+$ruleNames+'" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FileHashCondition>'
        foreach ($dll in $dllHashes)
        {
            $XML += '
                    <FileHash Type="SHA256" Data="'+$dll.Data+'" SourceFileName="'+$dll.SourceFileName+'" SourceFileLength="'+$dll.SourceFileLength+'" />'
        }
        $XML += '
                </FileHashCondition>
            </Conditions>
        </FileHashRule>'
    }
    if ($trustedDLLPublishers.Count -ne 0)
    {
        foreach ($publisher in $trustedDLLPublishers)
        {
            $XML += '
        <FilePublisherRule Id="'+[System.Guid]::NewGuid().Guid+'" Name="'+$ruleNames+': Signed by '+$publisher.PublisherName+'" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePublisherCondition PublisherName="'+$publisher.PublisherName+'" ProductName="*" BinaryName="*">
                    <BinaryVersionRange LowSection="*" HighSection="*" />
                </FilePublisherCondition>
            </Conditions>
        </FilePublisherRule>'
        }
    }
    $XML += '
    </RuleCollection>'
}
if (($exeHashes.Count -ne 0) -or ($trustedEXEPublishers.Count -ne 0))
{
    $XML += '
    <RuleCollection Type="Exe" EnforcementMode="NotConfigured">'
    if ($exeHashes.Count -ne 0)
    {
        $XML += '
        <FileHashRule Id="'+[System.Guid]::NewGuid().Guid+'" Name="'+$ruleNames+'" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FileHashCondition>'
        foreach ($exe in $exeHashes)
        {
            $XML += '
                    <FileHash Type="SHA256" Data="'+$exe.Data+'" SourceFileName="'+$exe.SourceFileName+'" SourceFileLength="'+$exe.SourceFileLength+'" />'
        }
        $XML += '
                </FileHashCondition>
            </Conditions>
        </FileHashRule>'
    }
    if ($trustedEXEPublishers.Count -ne 0)
    {
        foreach ($publisher in $trustedEXEPublishers)
        {
            $XML += '
        <FilePublisherRule Id="'+[System.Guid]::NewGuid().Guid+'" Name="'+$ruleNames+': Signed by '+$publisher.PublisherName+'" Description="" UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePublisherCondition PublisherName="'+$publisher.PublisherName+'" ProductName="*" BinaryName="*">
                    <BinaryVersionRange LowSection="*" HighSection="*" />
                </FilePublisherCondition>
            </Conditions>
        </FilePublisherRule>'
        }
    }
    $XML += '
    </RuleCollection>'
}
$XML += '
</AppLockerPolicy>'

if ($outFile.Length -ne 0)
{
    $XML | Out-File -FilePath $outFile -Encoding utf8
}
else
{
    Write-Host $XML
}
# SIG # Begin signature block
# MIIH4gYJKoZIhvcNAQcCoIIH0zCCB88CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUMhVDV9TnlpgG85LKYTzQmke
# wlGgggWQMIIFjDCCBO6gAwIBAgITGgAAAGDuqPRJRbwxxQAAAAAAYDAKBggqhkjO
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
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBS/HB4fuIV8mo8R9iM4HrfUOj8rfzALBgcq
# hkjOPQIBBQAEgYswgYgCQgF/eAV/kKo3Vxdksh4smt5EYn6ipc4Mjx+ubVE3qM3d
# L6V14be5XK7T74/H/861hMXZgysmMsHYhmaX5+6IO/9ULAJCAVZRlvS55eKDoIf2
# OPrWQYuGFY8xiLhluo4+JK6aqJlOLEAsd/1PmeCZG8Tm9dv+FDwGStjjILjeo+vQ
# ccYRXGHu
# SIG # End signature block
