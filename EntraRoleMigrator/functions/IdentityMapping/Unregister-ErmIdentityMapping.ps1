function Unregister-ErmIdentityMapping {
	<#
	.SYNOPSIS
		Removes a piece of identity mapping logic.
	
	.DESCRIPTION
		Removes a piece of identity mapping logic.
		Those are used to translate principal identities from the source tenant to the destination tenant.

		Use Register-ErmIdentityMapping to define new mappings.
		Use Get-ErmIdentityMapping to get a list of the currently provided mappings.
	
	.PARAMETER Type
		The type the mapping is for.
	
	.PARAMETER Name
		The name of the mapping to remove.
	
	.EXAMPLE
		PS C:\> Unregister-ErmIdentityMapping -Type user -Name MyTestMapping
		
		Removes the "MyTestMapping" that would translate identities for user objects.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('EntraRoleMigrator.IdentityMapping.Type')]
		[string]
		$Type,

		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('EntraRoleMigrator.IdentityMapping.Name')]
		[string]
		$Name
	)
	process {
		if (-not $script:_IdentityMapping[$Type]) {
			return
		}

		$script:_IdentityMapping[$Type].Remove($Name)
	}
}