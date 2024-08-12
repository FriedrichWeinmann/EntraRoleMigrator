function Get-ErmRole {
	<#
	.SYNOPSIS
		Read the roles available from the target tenant.
	
	.DESCRIPTION
		Read the roles available from the target tenant.
		Use "Connect-ErmService" first before using this command.
	
	.PARAMETER Tenant
		Whether to read from the source or destination tenant.
	
	.PARAMETER Id
		ID or displayname of the role to retrieve.
	
	.EXAMPLE
		PS C:\> Get-ErmRole -Tenant Source
		
		List all roles in the source tenant
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateSet('Source', 'Destination')]
		[string]
		$Tenant,

		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Id
	)
	begin {
		$service = "Graph-EntraRoleMigrator-$Tenant"
		Assert-ErmConnection -Service $Tenant -Cmdlet $PSCmdlet
	}
	process {
		if (-not $Id) {
			Invoke-EntraRequest -Service $service -Path 'roleManagement/directory/roleDefinitions' | Add-TypeName -Name 'EntraRoleMigrator.Role'
			return
		}

		foreach ($idEntry in $Id) {
			if ($idEntry -as [guid]) {
				Invoke-EntraRequest -Service $service -Path "roleManagement/directory/roleDefinitions/$idEntry" | Add-TypeName -Name 'EntraRoleMigrator.Role'
			}
			else {
				Invoke-EntraRequest -Service $service -Path "roleManagement/directory/roleDefinitions" -Query @{
					'$filter' = "displayName eq '$idEntry'"
				} | Add-TypeName -Name 'EntraRoleMigrator.Role'
			}
		}
	}
}