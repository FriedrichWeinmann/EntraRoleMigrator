function New-Change {
	<#
	.SYNOPSIS
		Helper function generating new change objects.
	
	.DESCRIPTION
		Helper function generating new change objects.
	
	.PARAMETER Action
		The action performed
	
	.PARAMETER Property
		The name of the property affected.
	
	.PARAMETER Value
		The value the property should have.
	
	.PARAMETER Name
		The name of the role.
	
	.PARAMETER ID
		The id of the role.
	
	.EXAMPLE
		PS C:\> New-Change -Action Update -Property DirectoryScopeId -Value $sourceAssignment.DirectoryScopeId -Name $matchingDest.RoleName -ID $matchingDest.RoleID

		Generates a new change based on the input provided.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Action,

		[string]
		$Property,

		$Value,

		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[string]
		$ID
	)
	process {
		[PSCustomObject]@{
			PSTypeName = 'EntraRoleMigrator.Change'
			Action     = $Action
			Property   = $Property
			Value      = $Value
			Name       = $Name
			ID         = $ID
		}
	}
}