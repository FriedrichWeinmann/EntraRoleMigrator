function New-TestResult {
	<#
	.SYNOPSIS
		Helper command, generates a unified test result object.
	
	.DESCRIPTION
		Helper command, generates a unified test result object.
		Used in Test-Erm* commands to report on the actions that need be taken.
		These objects will be used in their respective Invoke-Erm* commands to apply those changes.
	
	.PARAMETER Category
		The category of change needed.
	
	.PARAMETER Action
		The action performed against the object.
	
	.PARAMETER Identity
		The object being modified.
	
	.PARAMETER SourceObject
		The object from the source tenant.
		May be omitted in case of delete actions where no matching object can be found in the source tenant.
	
	.PARAMETER DestinationObject
		The object from the destination tenant.
		May be omitted in case of create actions, where no matching object can yet be found in the destination tenant.
	
	.PARAMETER Change
		Objects representing the actual change to perform.
	
	.EXAMPLE
		PS C:\> New-TestResult -Category Role -Action Update -Identity $destRole.displayName -SourceObject $sourceRole -DestinationObject $destRole -Change $changes

		Generates a test result, describing an update action against a role.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateSet('Role', 'Membership')]
		[string]
		$Category,

		[Parameter(Mandatory = $true)]
		[ValidateSet('Create', 'Update', 'Delete', 'Add', 'Remove', 'Ignore')]
		[string]
		$Action,

		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]
		$Identity,

		[AllowNull()]
		$SourceObject,

		[AllowNull()]
		$DestinationObject,

		[AllowEmptyCollection()]
		$Change
	)
	process {
		$obj = [PSCustomObject]@{
			PSTypeName  = 'EntraRoleMigrator.TestResult'
			Category    = $Category
			Action      = $Action
			Identity    = $Identity
			Source      = $SourceObject
			Destination = $DestinationObject
			Change      = $Change
		}
		[PSFramework.Object.ObjectHost]::AddScriptProperty($obj, 'ChangeDisplay', $script:_ResultDisplayStyles["$($Category)-$($Action)"])
		[PSFramework.Object.ObjectHost]::AddScriptMethod($obj, 'ToString', { $this.Identity })
		$obj
	}
}