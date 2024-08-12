function Test-ErmRoleMember {
	<#
	.SYNOPSIS
		Tests, what configuration discrepancies exist between source and destination tenant.
	
	.DESCRIPTION
		Tests, what configuration discrepancies exist between source and destination tenant.
		Requires a connection to both tenants.
		Use "Connect-ErmService" to establish such connections.
	
	.PARAMETER IncludeIgnored
		Whether ignored results should be included in the output.
		Discrepancies might be ignored if the principal cannot be found in the destination tenant.
	
	.EXAMPLE
		PS C:\> Test-ErmRoleMember

		Tests, what configuration discrepancies exist between source and destination tenant.
	#>
	[CmdletBinding()]
	param (
		[ValidateSet('All', 'Multiple', 'Unresolved', 'Unsupported', 'NoRole')]
		[string[]]
		$IncludeIgnored
	)
	begin {
		Assert-ErmConnection -Service Source -Cmdlet $PSCmdlet
		Assert-ErmConnection -Service Destination -Cmdlet $PSCmdlet

		#region Utility Functions
		function Get-IntendedAssignment {
			[CmdletBinding()]
			param (
				$Source,

				$Destination,

				[AllowEmptyCollection()]
				[AllowEmptyString()]
				[AllowNull()]
				[string[]]
				$IncludeIgnored
			)

			foreach ($sourceAssignment in $Source) {
				$identity = '{0}-->{1}' -f $sourceAssignment.RoleName, $sourceAssignment.Principal
				# Handle the cases we can't perform due to missing principal in destination or other related issues
				if ($sourceAssignment.TargetResult -ne 'Single') {
					if ('All' -in $IncludeIgnored -or $sourceAssignment.TargetType -in $IncludeIgnored) {
						New-TestResult -Category Membership -Action Ignore -SourceObject $sourceAssignment -Identity $identity -Change @(
							New-Change -Action Ignore -Property Issue -Value $sourceAssignment.TargetResult -Name $sourceAssignment.RoleName -ID $sourceAssignment.PrincipalID
						)
					}
					continue
				}
				if (-not $sourceAssignment.TargetRoleID) {
					if ('All' -in $IncludeIgnored -or 'NoRole' -in $IncludeIgnored) {
						New-TestResult -Category Membership -Action Ignore -SourceObject $sourceAssignment -Identity $identity -Change @(
							New-Change -Action Ignore -Property Issue -Value 'NoRole' -Name $sourceAssignment.RoleName -ID $sourceAssignment.PrincipalID
						)
					}
					continue
				}

				# Exclude matching assignments
				$matchingDest = $Destination | Where-Object {
					$_.RoleName -eq $sourceAssignment.RoleName -and
					$_.PrincipalType -eq $sourceAssignment.PrincipalType -and
					$_.AssignmentType -eq $sourceAssignment.AssignmentType -and
					$_.PrincipalID -eq $sourceAssignment.TargetID
				}
				if ($matchingDest) { continue }

				# Report missing assignments
				New-TestResult -Category Membership -Action Add -Identity $identity -SourceObject $sourceAssignment
			}
		}

		function Get-UndesiredAssignment {
			[CmdletBinding()]
			param (
				$Source,

				$Destination
			)

			foreach ($destinationAssignment in $Destination) {
				$identity = '{0}-->{1}' -f $destinationAssignment.RoleName, $destinationAssignment.Principal

				$matchingSource = $Source | Where-Object {
					$_.TargetResult -eq 'Single' -and
					$_.PrincipalType -eq $destinationAssignment.PrincipalType -and
					$_.RoleName -eq $destinationAssignment.RoleName -and
					$_.AssignmentType -eq $destinationAssignment.AssignmentType -and
					$_.TargetID -eq $destinationAssignment.PrincipalID
				}
				if ($matchingSource) { continue }

				New-TestResult -Category Membership -Action Remove -Identity $identity -DestinationObject $destinationAssignment
			}
		}

		function Get-UpdatedAssignment {
			[CmdletBinding()]
			param (
				$Source,

				$Destination
			)

			foreach ($sourceAssignment in $Source) {
				$matchingDest = $Destination | Where-Object {
					$_.RoleName -eq $sourceAssignment.RoleName -and
					$_.PrincipalType -eq $sourceAssignment.PrincipalType -and
					$_.AssignmentType -eq $sourceAssignment.AssignmentType -and
					$_.PrincipalID -eq $sourceAssignment.TargetID
				}
				if (-not $matchingDest) { continue }

				$changes = @()

				# Note: This may need further identity/resource resolution to properly match
				if ($sourceAssignment.DirectoryScopeId -ne $matchingDest.DirectoryScopeId) {
					$changes += New-Change -Action Update -Property DirectoryScopeId -Value $sourceAssignment.DirectoryScopeId -Name $matchingDest.RoleName -ID $matchingDest.RoleID
				}
				
				#region Eligibility Settings
				$propertyNames = 'ScheduleStart', 'ScheduleEnd', 'EligibleMemberType', 'AppScopeId'
				foreach ($propertyName in $propertyNames) {
					if ($sourceAssignment.$propertyName -eq $matchingDest.$propertyName) { continue }
					if ($propertyName -eq 'ScheduleStart') {
						# Assignments that are applicable right away will be created with the current time in the destination tenant
						# Thus, it will IGNORE Start timestamps that are in the past and assignments will not match timestamps in that scenario
						if (
							$sourceAssignment.ScheduleStart -lt (Get-Date).ToUniversalTime() -and
							$matchingDest.ScheduleStart -lt (Get-Date).ToUniversalTime()
						) { continue }
					}
					$changes += New-Change -Action Update -Property $propertyName -Value $sourceAssignment.$propertyName -Name $matchingDest.RoleName -ID $matchingDest.RoleID
				}
				#endregion Eligibility Settings


				if (-not $changes) { continue }

				$identity = '{0}-->{1}' -f $sourceAssignment.RoleName, $sourceAssignment.Principal
				New-TestResult -Category Membership -Action Update -Identity $identity -SourceObject $sourceAssignment -DestinationObject $matchingDest -Change $changes
			}
		}
		#endregion Utility Functions
	}
	process {
		# Get Assignments
		$sourceAssignments = Get-ErmRoleMember -Tenant Source
		$destinationAssignments = Get-ErmRoleMember -Tenant Destination

		# Map Source Identities to Destination Identities
		$extendedSourceAssignments = $sourceAssignments | Resolve-DestinationIdentity
		
		# Compare Assignments
		Get-IntendedAssignment -Source $extendedSourceAssignments -Destination $destinationAssignments -IncludeIgnored $IncludeIgnored
		Get-UndesiredAssignment -Source $extendedSourceAssignments -Destination $destinationAssignments
		Get-UpdatedAssignment -Source $extendedSourceAssignments -Destination $destinationAssignments
	}
}