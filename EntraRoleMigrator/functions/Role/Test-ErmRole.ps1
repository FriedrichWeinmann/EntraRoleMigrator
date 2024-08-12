function Test-ErmRole {
	<#
	.SYNOPSIS
		Tests, whether the destination tenant's role configuration differs from the source.
	
	.DESCRIPTION
		Tests, whether the destination tenant's role configuration differs from the source.
		Will return one entry per role deviation.

		Use Connect-ErmService twice first, to connect to both source and destination tenant.
	
	.EXAMPLE
		PS C:\> Test-ErmRole
		
		Tests, whether the destination tenant's role configuration differs from the source.
	#>
	[CmdletBinding()]
	param (
		
	)
	begin {
		Assert-ErmConnection -Service Source -Cmdlet $PSCmdlet
		Assert-ErmConnection -Service Destination -Cmdlet $PSCmdlet

		#region Utility Functions
		function Test-RoleDeletion {
			[CmdletBinding()]
			param (
				$Source,

				$Destination
			)

			foreach ($undesired in $Destination | Where-Object displayName -NotIn $Source.displayName) {
				if ($null -eq $undesired) { continue }
				New-TestResult -Category Role -Action Delete -Identity $undesired.DisplayName -DestinationObject $undesired -Change @(
					New-Change -Action Delete -Value $undesired -Name $undesired.displayName -ID $undesired.id
				)
			}
		}
		function Test-RoleCreation {
			[CmdletBinding()]
			param (
				$Source,
				$Destination
			)

			foreach ($intended in $Source | Where-Object displayName -NotIn $Destination.displayName) {
				if ($null -eq $intended) { continue }
				New-TestResult -Category Role -Action Create -Identity $intended.DisplayName -SourceObject $intended -Change @(
					New-Change -Action Create -Value $intended -Name $intended.displayName -ID $intended.id
				)
			}
		}
		function Test-RoleUpdate {
			[CmdletBinding()]
			param (
				$Source,
				$Destination
			)

			<#
			Notes:
			https://learn.microsoft.com/en-us/graph/api/resources/unifiedroledefinition?view=graph-rest-1.0#properties
			- resourceScopes is being deprecated in favor of them being tied to assignments.
			- rolePermissions/condition is for builtin roles only
			- rolePermissions/excludedResourceActions is not implemented yet
			#>

			foreach ($destRole in $Destination) {
				$sourceRole = $Source | Where-Object displayName -EQ $destRole.displayName
				# Create / Delete are handled outside of this function
				if (-not $sourceRole) { continue }

				$changes = @()
	
				# Description
				if ($sourceRole.Description -ne $destRole.Description) {
					$changes += New-Change -Action Update -Property description -Value $sourceRole.Description -Name $destRole.displayName -ID $destRole.id
				}

				# isEnabled
				if ($sourceRole.isEnabled -ne $destRole.isEnabled) {
					$changes += New-Change -Action Update -Property isEnabled -Value $sourceRole.isEnabled -Name $destRole.displayName -ID $destRole.id
				}

				# Role Permissions
				foreach ($permission in $sourceRole.rolePermissions.allowedResourceActions) {
					if ($permission -in $destRole.rolePermissions.allowedResourceActions) { continue }

					$changes += New-Change -Action AddRight -Value $permission -Name $destRole.displayName -ID $destRole.id
				}
				foreach ($permission in $destRole.rolePermissions.allowedResourceActions) {
					if ($permission -in $sourceRole.rolePermissions.allowedResourceActions) { continue }

					$changes += New-Change -Action RemoveRight -Value $permission -Name $destRole.displayName -ID $destRole.id
				}

				if (-not $changes) { continue }
				New-TestResult -Category Role -Action Update -Identity $destRole.displayName -SourceObject $sourceRole -DestinationObject $destRole -Change $changes
			}
		}
		#endregion Utility Functions
	}
	process {
		$rolesSource = Get-ErmRole -Tenant Source | Where-Object isBuiltIn -EQ $false
		$rolesDestination = Get-ErmRole -Tenant Destination | Where-Object isBuiltIn -EQ $false

		Test-RoleDeletion -Source $rolesSource -Destination $rolesDestination
		Test-RoleCreation -Source $rolesSource -Destination $rolesDestination
		Test-RoleUpdate -Source $rolesSource -Destination $rolesDestination
	}
}