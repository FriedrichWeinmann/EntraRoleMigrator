function Invoke-ErmRoleMember {
	<#
	.SYNOPSIS
		Synchronizes the destination tenant with the source tenant's role memberships.
	
	.DESCRIPTION
		Synchronizes the destination tenant with the source tenant's role memberships.

		DANGER!!!
		This command, if used inproperly, can cause significant harm to your ability to manage the destination tenant.

		If not other specified, it will compare source and destination tenant and correct anything in the destination tenant,
		that does not match the role assignment configuration of the source tenant.
		It will however not create any identies in the destiantion tenant - a user that only exists in the source will not have
		their role memberships applied in the destination until it is created there as well.

		You can preview all changes by calling "Test-ErmRoleMember"
		You can provide the result objects from "Test-ErmRoleMember" as input to this command to pick what changes to apply.
		You can use "Register-ErmIdentityMapping" to define, how principals are matched from the source tenant to the destination tenant.

		This command requires an established connection to both the source and destination tenants.
		Use "Connect-ErmService" to establish connections to either tenant.
	
	.PARAMETER TestResult
		The test results to execute.
		Only provide the result objects from "Test-ErmRoleMember" as input.
		If not specified, a full test will be executed and applied.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

	.EXAMPLE
		PS C:\> Invoke-ErmRoleMember

		Synchronizes the destination tenant with the source tenant's role memberships.
		Might be dangerous without first verifying the pending changes through Test-ErmRoleMember.

	.EXAMPLE
		PS C:\> $test | Invoke-ErmRoleMember

		Applies the changes in $test.
		This could be filtered results from Test-ErmRoleMember.

	.EXAMPLE
		PS C:\> Test-ErmRoleMember | Where-Object { $_.Source.Principal -eq 'FredAdm' .or $_.Destination.Principal -eq 'FredAdm' } | Invoke-ErmRoleMember

		Applies all pending changes regarding the user "FredAdm"
	#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$TestResult,

		[switch]
		$EnableException
	)

	begin {
		$serviceDestination = "Graph-EntraRoleMigrator-Destination"
		Assert-ErmConnection -Service Source -Cmdlet $PSCmdlet
		Assert-ErmConnection -Service Destination -Cmdlet $PSCmdlet

		function New-Schedule {
			[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
			[OutputType([hashtable])]
			[CmdletBinding()]
			param (
				[Parameter(Mandatory = $true)]
				[AllowEmptyCollection()]
				[AllowEmptyString()]
				[AllowNull()]
				$Start,

				[Parameter(Mandatory = $true)]
				[AllowEmptyCollection()]
				[AllowEmptyString()]
				[AllowNull()]
				$End,

				[Parameter(Mandatory = $true)]
				[AllowEmptyCollection()]
				[AllowEmptyString()]
				[AllowNull()]
				$Duration
			)

			$schedule = @{
				startDateTime = $Start
				recurrence = $null
				expiration = @{
					type = 'noExpiration'
					endDateTime = $null
					duration = $null
				}
			}
			if ($End) {
				$schedule.expiration.endDateTime = $End
				$schedule.expiration.type = 'afterDateTime'
			}
			if ($Duration) {
				$schedule.expiration.duration = $Duration
				$schedule.expiration.type = 'afterDuration'
			}

			$schedule
		}
	}
	process {
		$testObjects = $TestResult
		if (-not $testObjects) {
			$testObjects = Test-ErmRoleMember
		}

		foreach ($testItem in $testObjects) {
			#region Validation
			if ($testItem.PSObject.TypeNames -notcontains 'EntraRoleMigrator.TestResult') {
				Write-PSFMessage -Level Warning -Message 'Not a EntraRoleMigrator test result! {0}. Use Test-ErmRole to generate valid test results.' -StringValues $testItem -Target $testItem
				Write-Error "Not a EntraRoleMigrator test result! $testItem"
				continue
			}
			if ($testItem.Category -ne 'Membership') {
				Write-PSFMessage -Level Warning -Message 'Not a Role test result! Use Test-ErmRole to generate valid test results. Input: {0} -> {1}: {2}' -StringValues $testItem.Category, $testItem.Action, $testItem.Identity -Target $testItem
				Write-Error "Not a Role test result: $($testItem.Category) -> $($testItem.Action): $($testItem.Identity)"
				continue
			}
			#endregion Validation

			switch ($testItem.Action) {
				#region Add
				'Add' {
					switch ($testItem.Source.AssignmentType) {
						'Permanent' {
							Invoke-PSFProtectedCommand -Action "Permanently assigning $($testItem.Source.TargetName) to role $($testItem.Source.RoleName)" -Target $testItem -ScriptBlock {
								$null = Invoke-EntraRequest -Service $serviceDestination -Method POST -Path roleManagement/directory/roleAssignments -Body @{
									directoryScopeId = $testItem.Source.DirectoryScopeId
									principalId      = $testItem.Source.TargetID
									roleDefinitionId = $testItem.Source.TargetRoleID
								} -ErrorAction Stop
							} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
						}
						'Eligible' {
							Invoke-PSFProtectedCommand -Action "Assigning eligibility to $($testItem.Source.TargetName) to role $($testItem.Source.RoleName)" -Target $testItem -ScriptBlock {
								$null = Invoke-EntraRequest -Service $serviceDestination -Method POST -Path roleManagement/directory/roleEligibilityScheduleRequests -Body @{
									action           = 'AdminAssign'
									appScopeId       = $testItem.Source.AppScopeId
									directoryScopeId = $testItem.Source.DirectoryScopeId
									principalId      = $testItem.Source.TargetID
									roleDefinitionId = $testItem.Source.TargetRoleID
									justification    = 'Automated Role Membership Migration from tenant {0}' -f (Get-EntraToken -Service Graph-EntraRoleMigrator-Source).TenantId
									scheduleInfo     = New-Schedule -Start $testItem.Source.ScheduleStart -End $testItem.Source.ScheduleEnd -Duration $testItem.Source.ScheduleDuration
								}
							} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
						}
						default {
							$action = "Assigning $($testItem.Source.TargetName) to role $($testItem.Source.RoleName)"
							if ($testItem.Source.ScheduleEnd) { $action = "Assigning $($testItem.Source.TargetName) to role $($testItem.Source.RoleName) until $($testItem.Source.ScheduleEnd)" }
							if ($testItem.Source.ScheduleDuration) { $action = "Assigning $($testItem.Source.TargetName) to role $($testItem.Source.RoleName) for $($testItem.Source.ScheduleDuration)" }

							Invoke-PSFProtectedCommand -Action $action -Target $testItem -ScriptBlock {
								$null = Invoke-EntraRequest -Service $serviceDestination -Method POST -Path roleManagement/directory/roleAssignmentScheduleRequests -Body @{
									action           = 'AdminAssign'
									appScopeId       = $testItem.Source.AppScopeId
									directoryScopeId = $testItem.Source.DirectoryScopeId
									principalId      = $testItem.Source.TargetID
									roleDefinitionId = $testItem.Source.TargetRoleID
									justification    = 'Automated Role Membership Migration from tenant {0}' -f (Get-EntraToken -Service Graph-EntraRoleMigrator-Source).TenantId
									scheduleInfo     = New-Schedule -Start $testItem.Source.ScheduleStart -End $testItem.Source.ScheduleEnd -Duration $testItem.Source.ScheduleDuration
								}
							} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
						}
					}
				}
				#endregion Add

				#region Remove
				'Remove' {
					switch ($testItem.Destination.AssignmentType) {
						'Permanent' {
							Invoke-PSFProtectedCommand -Action "Permanently removing the assignment of $($testItem.Destination.Principal) to role $($testItem.Destination.RoleName)" -Target $testItem -ScriptBlock {
								$null = Invoke-EntraRequest -Service $serviceDestination -Method DELETE -Path "roleManagement/directory/roleAssignments/$($testItem.Destination.AssgignmentID)" -ErrorAction Stop
							} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
						}
						'Eligible' {
							Invoke-PSFProtectedCommand -Action "Unassigning eligibility of $($testItem.Destination.Principal) to role $($testItem.Destination.RoleName)" -Target $testItem -ScriptBlock {
								$null = Invoke-EntraRequest -Service $serviceDestination -Method POST -Path roleManagement/directory/roleEligibilityScheduleRequests -Body @{
									action           = 'adminRemove'
									appScopeId       = $testItem.Destination.AppScopeId
									directoryScopeId = $testItem.Destination.DirectoryScopeId
									principalId      = $testItem.Destination.PrincipalID
									roleDefinitionId = $testItem.Destination.RoleID
									justification    = 'Automated Role Membership Migration from tenant {0}' -f (Get-EntraToken -Service Graph-EntraRoleMigrator-Source).TenantId
								}
							} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
						}
						default {
							$action = "Unassigning $($testItem.Destination.Principal) from role $($testItem.Destination.RoleName)"
							if ($testItem.Destination.ScheduleEnd -or $testItem.Destination.ScheduleDuration) { $action = "Removing temporary assignment of $($testItem.Destination.Principal) from role $($testItem.Destination.RoleName)" }

							Invoke-PSFProtectedCommand -Action $action -Target $testItem -ScriptBlock {
								$null = Invoke-EntraRequest -Service $serviceDestination -Method POST -Path roleManagement/directory/roleAssignmentScheduleRequests -Body @{
									action           = 'adminRemove'
									appScopeId       = $testItem.Destination.AppScopeId
									directoryScopeId = $testItem.Destination.DirectoryScopeId
									principalId      = $testItem.Destination.PrincipalID
									roleDefinitionId = $testItem.Destination.RoleID
									justification    = 'Automated Role Membership Migration from tenant {0}' -f (Get-EntraToken -Service Graph-EntraRoleMigrator-Source).TenantId
								}
							} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
						}
					}
				}
				#endregion Remove

				#region Update
				'Update' {
					throw "Not Implemented Yet!"
				}
				#endregion Update

				#region Ignore
				'Ignore' {
					Write-PSFMessage -Level Verbose -Message 'Skipping Ignored Test Result: {0} ({1})' -StringValues $testItem.Identity, $testItem.ChangeDisplay -Target $testItem
				}
				#endregion Ignore
			}
		}
	}
}