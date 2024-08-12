function Resolve-DestinationIdentity {
	<#
	.SYNOPSIS
		Resolves an identity in the destination tenant.
	
	.DESCRIPTION
		Resolves an identity in the destination tenant.
		Centerpiece implementing the Identity Mapping component.
	
	.PARAMETER InputObject
		An assignment object to extend with target identity information.
		Would usually be a role membership object from the source tenant.
	
	.EXAMPLE
		PS C:\> $sourceAssignments | Resolve-DestinationIdentity

		Extends the role assignment information from the source tenant to matching identities in the destination tenant.
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)

	begin {
		$identityCache = @{ }
		# Prepare for mapping to target tenant
		$targetRoleCache = @{ }
		foreach ($role in Get-ErmRole -Tenant Destination) {
			$targetRoleCache[$role.displayName] = $role
		}
		$supportedTypes = [enum]::GetNames([EntraRoleMigrator.PrincipalType])
	}
	process {
		foreach ($assignment in $InputObject) {
			if ($identityCache[$assignment.PrincipalID]) {
				[PSFramework.Object.ObjectHost]::AddNoteProperty(
					$assignment,
					@{
						TargetID     = $identityCache[$assignment.PrincipalID].Id
						TargetName   = $identityCache[$assignment.PrincipalID].Name
						TargetType   = $identityCache[$assignment.PrincipalID].Type
						TargetResult = $identityCache[$assignment.PrincipalID].Result
						TargetRoleID = $targetRoleCache[$assignment.RoleName].id
					}
				)
				$assignment
				continue
			}

			if ($assignment.PrincipalType -notin $supportedTypes) {
				$identityCache[$assignment.PrincipalID] = [PSCustomObject]@{
					Id     = $null
					Name   = $null
					Type   = $assignment.PrincipalType
					Result = 'Unsupported'
				}
				[PSFramework.Object.ObjectHost]::AddNoteProperty(
					$assignment,
					@{
						TargetID     = $identityCache[$assignment.PrincipalID].Id
						TargetName   = $identityCache[$assignment.PrincipalID].Name
						TargetType   = $identityCache[$assignment.PrincipalID].Type
						TargetResult = $identityCache[$assignment.PrincipalID].Result
						TargetRoleID = $targetRoleCache[$assignment.RoleName].id
					}
				)
				$assignment
				continue
			}

			$identityMap = Resolve-ErmIdentityMap -Principal $assignment.PrincipalObject -Type $assignment.PrincipalType
			$identityResult = foreach ($identityOption in $identityMap | Sort-Object Priority) {
				if (-not $identityOption.Value) { continue }
				$identity = Get-Identity -Tenant Destination -Type $identityOption.Type -Property $identityOption.Property -Value $identityOption.Value
				if ($identity) {
					$identity
					break
				}
			}

			if ($identityResult) { $identityCache[$assignment.PrincipalID] = $identityResult }
			else {
				$identityCache[$assignment.PrincipalID] = [PSCustomObject]@{
					Id     = $null
					Name   = $null
					Type   = $assignment.PrincipalType
					Result = 'Unresolved'
				}
			}

			[PSFramework.Object.ObjectHost]::AddNoteProperty(
				$assignment,
				@{
					TargetID     = $identityCache[$assignment.PrincipalID].Id
					TargetName   = $identityCache[$assignment.PrincipalID].Name
					TargetType   = $identityCache[$assignment.PrincipalID].Type
					TargetResult = $identityCache[$assignment.PrincipalID].Result
					TargetRoleID = $targetRoleCache[$assignment.RoleName].id
				}
			)
			$assignment
		}
	}
}