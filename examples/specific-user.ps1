<#
A simple role & role membership replication script that will only migrate role assignments for a single user.
Insert tenant & client IDs for your own environment.
This code uses interactive logon, so the user will be twice prompted to log into an account in the browser:
First for the source Tenant, then for the destination Tenant.

More Information:
+ Configure Authentication in the Portal: https://github.com/FriedrichWeinmann/EntraAuth/blob/master/docs/overview.md
+ Rights needed: ../permissions.md
#>

$sourceTenantID = '<tenantid>'
$sourceClientID = '<clientid>'
$destTenantID = '<tenantid>'
$destClientID = '<clientid>'

Connect-ErmService -Type Source -ClientID $sourceClientID -TenantID $sourceTenantID
Connect-ErmService -Type Destination -ClientID $destClientID -TenantID $destTenantID

Register-ErmIdentityMapping -Type user -Name default -Priority 100 -SourceProperty userPrincipalName -DestinationProperty userPrincipalName -Conversion { $_ -replace 'fabrikam.org', 'contoso.com' }
Invoke-ErmRole -Confirm:$false
Test-ErmRoleMember | Where-Object {
	$_.Destination.PrincipalID -eq '57215514-03b2-49fe-b683-219e9d74fb94' -or
	$_.Source.PrincipalID -eq '8ec8cb54-a9e7-4cd1-aa0d-1a54edd9866d'
} | Invoke-ErmRoleMember -Confirm:$false