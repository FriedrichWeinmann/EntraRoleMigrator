function Get-Identity {
	<#
	.SYNOPSIS
		Tries to resolve principals based on the filter criteria provided.
	
	.DESCRIPTION
		Tries to resolve principals based on the filter criteria provided.
		Helper function that is part of making the Identity Mapping feature work.
	
	.PARAMETER Tenant
		The tenant to search the principal for.
		Should generally be "Destination"
	
	.PARAMETER Type
		The type of principal we are trying to find.
	
	.PARAMETER Property
		The name of the property to filter by.
	
	.PARAMETER Value
		The value the property should have on that principal.
	
	.EXAMPLE
		PS C:\> Get-Identity -Tenant Destination -Type user -Property userPrincipalName -Value fred@fabrikam.org

		Looks in the destination tenant for the user with a UPN named "fred@fabrikam.org"
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateSet('Source', 'Destination')]
		[string]
		$Tenant,

		[Parameter(Mandatory = $true)]
		[EntraRoleMigrator.PrincipalType]
		$Type,

		[Parameter(Mandatory = $true)]
		[string]
		$Property,

		[Parameter(Mandatory = $true)]
		$Value
	)
	begin {
		Assert-ErmConnection -Service $Tenant -Cmdlet $PSCmdlet
		$service = "Graph-EntraRoleMigrator-$Tenant"
	}
	process {
		switch ("$Type") {
			'user' {
				$result = Invoke-EntraRequest -Service $service -Path 'users' -Query @{
					'$filter' = ('{0} eq ''{1}''' -f $Property, $Value) -replace '#','%23'
					'$select' = 'id,userPrincipalName'
				}
				if (-not $result) { return }
				if (@($result).Count -gt 1) {
					Write-PSFMessage -Level Error -Message 'Error resolving user in {0} for property {1} and value {2} - Multiple matches detected! Non-unique identities will not be matched for role memberships.' -StringValues $Tenant, $Property, $Value -Tag Duplicate -Data @{ EventID = 400 }
					foreach ($entry in $result) {
						Write-PSFMessage -Level Warning -Message '  User {0} (ID: {1})' -StringValues $entry.userPrincipalName, $entry.ID
					}
					[PSCustomObject]@{
						Id     = $result.id
						Name   = $result.userPrincipalName
						Type   = 'User'
						Result = 'Multiple'
					}
					return
				}

				[PSCustomObject]@{
					Id     = $result.id
					Name   = $result.userPrincipalName
					Type   = 'User'
					Result = 'Single'
				}
			}
			'servicePrincipal' {
				$result = Invoke-EntraRequest -Service $service -Path 'applications' -Query @{
					'$filter' = ('{0} eq ''{1}''' -f $Property, $Value) -replace '#','%23'
					'$select' = 'id,displayName'
				}
				if (-not $result) { return }

				if (@($result).Count -gt 1) {
					Write-PSFMessage -Level Error -Message 'Error resolving ServicePrincipal in {0} for property {1} and value {2} - Multiple matches detected! Non-unique identities will not be matched for role memberships.' -StringValues $Tenant, $Property, $Value -Tag Duplicate -Data @{ EventID = 401 }
					foreach ($entry in $result) {
						Write-PSFMessage -Level Warning -Message '  ServicePrincipal {0} (ID: {1})' -StringValues $entry.displayName, $entry.ID
					}
					[PSCustomObject]@{
						Id     = $result.id
						Name   = $result.displayName
						Type   = 'servicePrincipal'
						Result = 'Multiple'
					}
					return
				}

				[PSCustomObject]@{
					Id     = $result.Id
					Name   = $result.displayName
					Type   = 'servicePrincipal'
					Result = 'Single'
				}
			}
			default {
				throw "Identity type $Type Not Implemented Yet!"
			}
		}
	}
}