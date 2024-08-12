<#
A simple role test script, previewing what would need to happen to bring the destination tenant into the desired state..
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

Register-ErmIdentityMapping -Type user -Name default -Priority 100 -SourceProperty userPrincipalName -DestinationProperty userPrincipalName -Conversion { $_ -replace 'fabrikam.org','contoso.com' }
Test-ErmRole
Test-ErmRoleMember