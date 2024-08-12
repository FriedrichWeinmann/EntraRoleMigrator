function Invoke-ErmRole {
	<#
	.SYNOPSIS
		Remediates all differences between source and destination role configurations.
	
	.DESCRIPTION
		Remediates all differences between source and destination role configurations.
		This command will either run a full comparison between all custom roles or only apply the results provided to it from previous test runs.
	
	.PARAMETER TestResult
		Results to execute.
		Use Test-ErmRole to get a list of differences to remediate.
		This parameter allows cherrypicking, what differences to apply.
		By default, this command will run a full scan and remediate all deltas.
	
	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
	
	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

	.EXAMPLE
		PS C:\> Invoke-ErmRole
		
		Remediates all differences between source and destination role configurations.

	.EXAMPLE
		PS C:\> Invokre-ErmRole -TestResult $results[0]

		Only applies a single test result from a previous Test-ErmRole execution.
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
	}
	process {
		$testObjects = $TestResult
		if (-not $testObjects) {
			$testObjects = Test-ErmRole
		}

		foreach ($testItem in $testObjects) {
			#region Validation
			if ($testItem.PSObject.TypeNames -notcontains 'EntraRoleMigrator.TestResult') {
				Write-PSFMessage -Level Warning -Message 'Not a EntraRoleMigrator test result! {0}. Use Test-ErmRole to generate valid test results.' -StringValues $testItem -Target $testItem
				Write-Error "Not a EntraRoleMigrator test result! $testItem"
				continue
			}
			if ($testItem.Category -ne 'Role') {
				Write-PSFMessage -Level Warning -Message 'Not a Role test result! Use Test-ErmRole to generate valid test results. Input: {0} -> {1}: {2}' -StringValues $testItem.Category, $testItem.Action, $testItem.Identity -Target $testItem
				Write-Error "Not a Role test result: $($testItem.Category) -> $($testItem.Action): $($testItem.Identity)"
				continue
			}
			#endregion Validation

			switch ($testItem.Action) {
				#region Create
				'Create' {
					$body = @{
						description = $testItem.Source.description
						displayName = $testItem.Source.displayName
						rolePermissions = @(
							@{
								allowedResourceActions = @(
									$testItem.Source.rolePermissions.allowedResourceActions
								)
							}
						)
						isEnabled = $testItem.Source.isEnabled
					}

					Invoke-PSFProtectedCommand -Action "Creating Custom Role $($testItem.Source.displayName)" -Target $testItem -ScriptBlock {
						$null = Invoke-EntraRequest -Service $serviceDestination -Method POST -Path 'roleManagement/directory/roleDefinitions' -Body $body
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Create

				#region Delete
				'Delete' {
					Invoke-PSFProtectedCommand -Action "Deleting Custom Role $($testItem.Destination.displayName)" -Target $testItem -ScriptBlock {
						$null = Invoke-EntraRequest -Service $serviceDestination -Method Delete -Path "roleManagement/directory/roleDefinitions/$($testItem.Destination.Id)"
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Delete

				#region Update
				'Update' {
					$body = @{ }
					foreach ($change in $testItem.Change) {
						switch ($change.Action) {
							"Update" {
								Write-PSFMessage -Message 'Planning Role Update - {0} ({1}): Setting {2} to {3}' -StringValues $testItem.Destination.displayName, $testItem.Destination.id, $change.Property, $change.Value
								$body[$change.Property] = $change.Value
							}
							'AddRight' {
								Write-PSFMessage -Message 'Planning Role Update - {0} ({1}): Adding right "{2}"' -StringValues $testItem.Destination.displayName, $testItem.Destination.id, $change.Value
								$body['rolePermissions'] = @(
									@{
										allowedResourceActions = @(
											$testItem.Source.rolePermissions.allowedResourceActions
										)
									}
								)
							}
							'RemoveRight' {
								Write-PSFMessage -Message 'Planning Role Update - {0} ({1}): Removing right "{2}"' -StringValues $testItem.Destination.displayName, $testItem.Destination.id, $change.Value
								$body['rolePermissions'] = @(
									@{
										allowedResourceActions = @(
											$testItem.Source.rolePermissions.allowedResourceActions
										)
									}
								)
							}
						}
					}
					Invoke-PSFProtectedCommand -Action "Updating Custom Role $($testItem.Destination.displayName)" -Target $testItem -ScriptBlock {
						$null = Invoke-EntraRequest -Service $serviceDestination -Method Patch -Path "roleManagement/directory/roleDefinitions/$($testItem.Destination.Id)" -Body $body
					} -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue
				}
				#endregion Update
			}
		}
	}
}