function Register-ErmIdentityMapping {
	<#
	.SYNOPSIS
		Registers a new identity translation logic.
	
	.DESCRIPTION
		Registers a new identity translation logic.
		These are used to match principals from the source tenant to those in the destination tenants.
		They can only take a single property from the source identity and try to convert it to the expected value in the destination tenant.

		This allows matching users or service principals based on attributes.
		For example, a user with a UPN of "<username>@contoso.com" in the source tenant, could be matched to a user with the UPN of "<username>@fabrikam.org" in the destination tenant.

		Multiple mapping methods can be provided for a single object type - they will be processed in the order of priority,
		with lower numbers taking precedence over higher numbers.
	
	.PARAMETER Type
		The type of object the mapping is for.
		Supports "User" or "ServicePrincipal"
	
	.PARAMETER Name
		The name to assign to the mapping.
		Has no technical impact, but allows overriding / removing mappings later on.
	
	.PARAMETER Priority
		The priority of the mapping.
		The lower the number, the earlier it is used when translating identities.
		For any given identity, the first mapping that finds a result in the destination tenant wins.
	
	.PARAMETER SourceProperty
		The property on the principal object from the source tenant to use.
	
	.PARAMETER DestinationProperty
		The property on the principal object from the destination tenant, that will be expected to have the value
		the conversion logic generates from the value on the source property of the source object.
	
	.PARAMETER Conversion
		The scriptblock used to take the value of the source property, to calculate the value expected on the destination object.
		This scriptblock will receive the input value from the source object as "$_"
	
	.EXAMPLE
		PS C:\> Register-ErmIdentityMapping -Type user -Name default -Priority 100 -SourceProperty userPrincipalName -DestinationProperty userPrincipalName -Conversion { $_ -replace 'contoso.com','fabrikam.org' }

		This will provide a simple translation based on UPN of users.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[EntraRoleMigrator.PrincipalType]
		$Type,

		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[int]
		$Priority = 50,

		[Parameter(Mandatory = $true)]
		[string]
		$SourceProperty,

		[Parameter(Mandatory = $true)]
		[string]
		$DestinationProperty,

		[Parameter(Mandatory = $true)]
		[PsfScriptblock]
		$Conversion
	)
	process {
		if (-not $script:_IdentityMapping["$Type"]) {
			$script:_IdentityMapping["$Type"] = @{ }
		}

		$script:_IdentityMapping["$Type"][$Name] = [PSCustomObject]@{
			PSTypeName          = 'EntraRoleMigrator.IdentityMapping'
			Name                = $Name
			Type                = "$Type"
			Priority            = $Priority
			SourceProperty      = $SourceProperty
			DestinationProperty = $DestinationProperty
			Conversion          = $Conversion
		}
	}
}