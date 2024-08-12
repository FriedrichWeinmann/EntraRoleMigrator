Register-PSFTeppScriptblock -Name 'EntraRoleMigrator.IdentityMapping.Type' -ScriptBlock {
	(Get-ErmIdentityMapping).Type | Sort-Object -Unique
}

Register-PSFTeppScriptblock -Name 'EntraRoleMigrator.IdentityMapping.Name' -ScriptBlock {
	$type = '*'
	if ($fakeBoundParameters.Type) {$type = $fakeBoundParameters.Type }
	(Get-ErmIdentityMapping -Type $type).Name | Sort-Object -Unique
}