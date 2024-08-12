function Get-ErmRoleMember {
	<#
	.SYNOPSIS
		Lists all members of a role.
	
	.DESCRIPTION
		Lists all members of a role.
		Will include direct assignments, assignment requests and eligibility requests.

		Requires an established connection to either the source or destination tenant.
		Use "Connect-ErmService" to establish such a connection.
	
	.PARAMETER Tenant
		The tenant to search.
	
	.PARAMETER Id
		The ID of the role for which to find members.
		Can be either an actual ID or the name of the role.
	
	.EXAMPLE
		PS C:\> Get-ErmRoleMember

		Get a list of all role memberships across all roles.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateSet('Source', 'Destination')]
		[string]
		$Tenant,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[PsfValidatePattern('^(([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12})$', ErrorMessage = 'Not a valid Guid / ID')]
		[string[]]
		$Id
	)
	begin {
		$service = "Graph-EntraRoleMigrator-$Tenant"
		Assert-ErmConnection -Service $Tenant -Cmdlet $PSCmdlet

		$roleCache = @{ }
		# Permanent Assignments should be deduplicated from direct role memberships
		$assignCache = @{ }

		$endpointPaths = @(
			'roleManagement/directory/roleEligibilityScheduleRequests'
			'roleManagement/directory/roleAssignmentScheduleRequests'
			'roleManagement/directory/roleAssignments'
		)
	}
	process {
		foreach ($endpointPath in $endpointPaths) {
			if (-not $Id) {
				$query = @{ '$expand' = 'principal' }
				if ($endpointPath -eq 'roleManagement/directory/roleEligibilityScheduleRequests') {
					# $query['$filter'] = "action eq 'adminAssign'"
					$query['$filter'] = "status eq 'Provisioned' or Status eq 'Revoked'"
				}
				if ($endpointPath -eq 'roleManagement/directory/roleAssignmentScheduleRequests') {
					# $query['$filter'] = "action eq 'adminAssign'"
					$query['$filter'] = "status eq 'Provisioned' or Status eq 'Revoked'"
				}
				try {
					Invoke-EntraRequest -Service $service -Path $endpointPath -ErrorAction Stop -Query $query |
						ConvertTo-RoleMembership -Roles $roleCache -Tenant $Tenant -Path $endpointPath -Assigned $assignCache
				}
				catch { $PSCmdlet.WriteError($_) }
				continue
			}
	
			foreach ($roleID in $Id) {
				$query = @{
					'$expand' = 'principal'
					'$filter' = "roleDefinitionId eq '$roleID'"
				}
				if ($endpointPath -eq 'roleManagement/directory/roleEligibilityScheduleRequests') {
					# $query['$filter'] = "roleDefinitionId eq '$roleID' and action eq 'adminAssign'"
					$query['$filter'] = "roleDefinitionId eq '$roleID' and status eq 'Provisioned'"
				}
				if ($endpointPath -eq 'roleManagement/directory/roleAssignmentScheduleRequests') {
					# $query['$filter'] = "roleDefinitionId eq '$roleID' and action eq 'adminAssign'"
					$query['$filter'] = "roleDefinitionId eq '$roleID' and status eq 'Provisioned'"
				}
				try {
					Invoke-EntraRequest -Service $service -Path $endpointPath -ErrorAction Stop -Query $query |
						ConvertTo-RoleMembership -Roles $roleCache -Tenant $Tenant -Path $endpointPath -Assigned $assignCache
				}
				catch { $PSCmdlet.WriteError($_) }
			}
		}
	}
}