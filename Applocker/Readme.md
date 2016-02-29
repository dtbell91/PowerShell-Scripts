Get-ApplockerRules - Creates a hashtable containing the Applocker rules from a particular directory
Get-ApplockerXMLRules - Converts a hashtable containing Applocker rules into an XML file suitable for importing into a group policy object
Join-ApplockerRuleSet - Joins multiple hashtables containing Applocker rules and returns one hashtable
Load-ApplockerRuleSet - Loads an Applocker rule set from an XML file into a hashtable

Example Process
Follow these steps when you need to add a new application to the whitelist or update an existing listing.
In this example, I will be adding the December 2015 Bloomberg software.

	1. Identify the install location of the software. Ideally, this should be a fresh/trusted install.
	2. Run the following command, substituting the location of the application
	$rules = .\Get-ApplockerRules.ps1 -path "C:\path\to\scan"
	3. Respond to any prompts about publisher or hash rules as required.
	4. Run the following command to remove any duplicate file hashes
	$rules2 = .\Join-ApplockerRuleSet.ps1 -rulesets $rules
	5. Run the following command to export the rules to XML 
	.\Get-ApplockerXMLRules.ps1 -ruleset $rules2 -ruleNames "Rule Name" -outFile "c:\path\to\rules.xml"
	6. Then, as a Domain Administrator, run the following command to merge your new rules into the Group Policy Object
	Set-AppLockerPolicy -XMLPolicy c:\path\to\rules.xml -LDAP "LDAP://domaincontroller/CN=PathToGPO" -Merge
