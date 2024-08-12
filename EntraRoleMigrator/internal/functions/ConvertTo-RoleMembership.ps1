function ConvertTo-RoleMembership {
	<#
	.SYNOPSIS
		Converts the various API results into full, uniform role membership assignments data.
	
	.DESCRIPTION
		Converts the various API results into full, uniform role membership assignments data.
	
	.PARAMETER Roles
		A hashtable used to cache role data.
		Otherwise, we might repeatedly resolve the same role object.
	
	.PARAMETER Tenant
		What tenant to resolve roles from.
	
	.PARAMETER Path
		What API path was queries.
		Some resolution steps are specific to the path the objects are received from.
	
	.PARAMETER Assigned
		A hashtable to cache those principals, that have been actively assigned by assignment schedule request.
		This is used to later not report the same result from the active direct role assignments, as that apie ALSO reports
		assignments from the PIM assignment APIs.
	
	.PARAMETER InputObject
		The API-response object(s) to convert.
	
	.EXAMPLE
		PS C:\> Invoke-EntraRequest -Service $service -Path $endpointPath -ErrorAction Stop -Query $query | ConvertTo-RoleMembership -Roles $roleCache -Tenant $Tenant -Path $endpointPath -Assigned $assignCache
	
		Converts all the response objects into proper role membership objects.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[hashtable]
		$Roles,

		[Parameter(Mandatory = $true)]
		[string]
		$Tenant,

		[Parameter(Mandatory = $true)]
		[string]
		$Path,

		[Parameter(Mandatory = $true)]
		[hashtable]
		$Assigned,

		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)

	begin {
		$assignmentType = 'Permanent'
		if ($Path -eq 'roleManagement/directory/roleEligibilityScheduleRequests') {
			$assignmentType = 'Eligible'
		}

		$results = [System.Collections.ArrayList]@()
		$allItems = [System.Collections.ArrayList]@()
	}
	process {
		if (-not $InputObject) { return }
		$null = $allItems.Add($InputObject)

		if (-not $Roles[$InputObject.roleDefinitionId]) {
			$Roles[$InputObject.roleDefinitionId] = Get-ErmRole -Id $InputObject.roleDefinitionId -Tenant $Tenant
		}

		$isScheduleRequest = $InputObject.PSObject.Properties.Name -contains 'scheduleInfo'
		if ($isScheduleRequest -and $InputObject.status -ne 'Provisioned') { return }

		if ($Path -eq 'roleManagement/directory/roleAssignmentScheduleRequests') {
			if (-not $InputObject.scheduleInfo.expiration.endDateTime) {
				$assignmentType = 'PermAssigned'
			}
			else {
				$assignmentType = 'TempAssigned'
			}
		}
		if ($assignmentType -eq 'PermAssigned') {
			$Assigned["$($InputObject.roleDefinitionId)|$($InputObject.principalId)"] = $true
		}
		if ($assignmentType -eq 'Permanent' -and $Assigned["$($InputObject.roleDefinitionId)|$($InputObject.principalId)"]) {
			return
		}
		# Only schedule requests that are "AdminAssign" are actual eligibility assignments
		if ($assignmentType -eq 'Eligible' -and $InputObject.action -ne 'AdminAssign') {
			return
		}

		$entry = [PSCustomObject]@{
			PSTypeName         = 'EntraRoleMigrator.RoleMember'
			RoleID             = $InputObject.roleDefinitionId
			RoleName           = $Roles[$InputObject.roleDefinitionId].DisplayName
			AssignmentType     = $assignmentType
			PrincipalID        = $InputObject.principalId
			PrincipalType      = $InputObject.principal.'@odata.type' -replace '^.+\.'
			Principal          = $InputObject.principal.displayName
			DirectoryScopeId   = $InputObject.directoryScopeId
			AccountEnabled     = $InputObject.principal.AccountEnabled

			AssgignmentID      = $InputObject.id

			# Eligibility Configuration
			ScheduleStart      = $InputObject.scheduleInfo.startDateTime
			ScheduleEnd        = $InputObject.scheduleInfo.expiration.endDateTime
			ScheduleDuration   = $InputObject.scheduleInfo.expiration.duration
			EligibleAction     = $InputObject.action
			EligibleMemberType = $InputObject.memberType
			AppScopeId         = $InputObject.appScopeId

			RoleObject         = $Roles[$InputObject.roleDefinitionId]
			PrincipalObject    = $InputObject.principal
			AssignmentObject   = $InputObject
		}
		$null = $results.Add($entry)
	}
	end {
		# All this only because the API will include open PIM-API requests for 30 days after they stop mattering ...
		$revocations = $allItems | Where-Object action -eq adminRemove

		foreach ($item in $results) {
			# Permanent Assignments are just fine
			if ($item.AssignmentType -eq 'Permanent') {
				$item
				continue
			}

			# Was this request revoked at a later time?
			if (
				$revocations | Where-Object {
					$_.roleDefinitionId -eq $item.RoleID -and
					$_.principalId -eq $item.PrincipalID -and
					$_.appScopeId -eq $item.AppScopeId -and
					$_.directoryScopeId -eq $item.DirectoryScopeId -and
					$_.createdDateTime -ge $item.AssignmentObject.createdDateTime
				}
			) { continue }

			$item
		}
	}
}