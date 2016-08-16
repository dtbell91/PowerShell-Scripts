###########################################################################
#
# NAME: Import-ADUserDetails.ps1
#
# AUTHOR: David Bell
#
# COMMENT: This script imports user details (office/mobile phone, fax, title, notes) into their AD objects.
#          Useful for mass updating all users details (eg. if we got a new fax number or changed address)
#
# VERSION HISTORY:
# 1.0 05.11.2014 - Initial release
#
###########################################################################

# Set the source .csv file to use. The first row should define the names of each field (with at least identity defined)
$csvfile = Import-Csv "\\path\to\csv\file\userdetails.csv"

foreach ($user in $csvfile)
{
    # create an empty Hashtable (replace) and an empty array (clear) for use in updating the user
    $replace = @{}
    $clear = @()

    # step through each property in the csv file and assign it to either replace or clear
    $user.psobject.Properties | foreach {
                                            if ($_.Name -eq "identity") {} #do nothing, we don't want to replace the user's identity
                                            elseif ($_.value -ne "") {$replace[$_.Name] = $_.Value }
                                            elseif ($_.value -eq "") {$clear+= ,$_.Name}
                                        }
    # print everything out, useful for testing
    "User: "+$user.identity
    "Replace:"
    $replace
    "Clear:"
    $clear
    "`n"
    
    # splat the parameters needed to run set-aduser, but only if they are actually used. Set-ADUser responds badly if passed empty arrays/hashtables
    $params = @{}
    if ($replace.Count -ne 0) { $params.Replace = $replace }
    if ($clear.Count -ne 0) { $params.Clear = $clear }

    # run the update with the parameters
    Set-ADUser -Identity $user.identity @params
}
