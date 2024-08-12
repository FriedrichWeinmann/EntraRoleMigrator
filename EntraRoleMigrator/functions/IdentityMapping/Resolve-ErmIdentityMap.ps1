function Resolve-ErmIdentityMap {
	<#
	.SYNOPSIS
		Calculates the values to search for in the dextination tenant, based on a principal from the source tenant.
	
	.DESCRIPTION
		Calculates the values to search for in the dextination tenant, based on a principal from the source tenant.
		This generates the search values from the principal from the source tenant, that will later be used to figure out
		the matching principal in the destination tenant.

		Used to make sure role memberships are properly translated.
	
	.PARAMETER Principal
		The principal object from the source tenant to translate.
	
	.PARAMETER Type
		What kind of principal type to translate.
	
	.EXAMPLE
		PS C:\> Resolve-ErmIdentityMap -Principal $assignment.principal -Type user

		Generates the possible, expected values to look for the user on an assignment.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$Principal,

		[Parameter(Mandatory = $true)]
		[EntraRoleMigrator.PrincipalType]
		$Type
	)
	process {
		foreach ($mapping in $script:_IdentityMapping."$Type".Values | Sort-Object Priority) {
			try {
				$result = $mapping.Conversion.InvokeGlobal($Principal.$($mapping.SourceProperty))
				[PSCustomObject]@{
					Type     = $Type
					Priority = $mapping.Priority
					Value    = $($result)
					Property = $mapping.DestinationProperty
				}
			}
			catch {
				Write-PSFMessage -Level Warning -Message 'Failed to process mapping {0} for type {1} on principal {2}' -StringValues $mapping.Name, $mapping.Type, $Principal.Id -ErrorRecord $_
			}
		}
	}
}