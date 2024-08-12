function Get-ErmIdentityMapping {
	<#
	.SYNOPSIS
		Lists any registered identity translation/mapping logic.
	
	.DESCRIPTION
		Lists any registered identity translation/mapping logic.
		Those are used to match identities across tenants.

		Use Register-ErmIdentityMapiing to provide new mapping logic.
	
	.PARAMETER Type
		Filter by the principal type the mapping is for.
		Defaults to: *
	
	.PARAMETER Name
		Filter by the name assigned to the mapping.
		Defaults to: *
	
	.EXAMPLE
		PS C:\> Get-ErmIdentityMapping

		Lists all registered Identity Mappings.
	#>
	[CmdletBinding()]
	param (
		[PsfArgumentCompleter('EntraRoleMigrator.IdentityMapping.Type')]
		[string]
		$Type = '*',

		[PsfArgumentCompleter('EntraRoleMigrator.IdentityMapping.Name')]
		[string]
		$Name = '*'
	)
	process {
		($script:_IdentityMapping.Values.Values) | Where-Object {
			$_.Type -like $Type -and
			$_.Name -like $Name
		}
	}
}