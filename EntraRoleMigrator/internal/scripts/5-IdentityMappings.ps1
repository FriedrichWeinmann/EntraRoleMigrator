$param = @{
	Type = 'user'
	Name = 'default'
	Priority = 100
	SourceProperty = 'userPrincipalName'
	DestinationProperty = 'userPrincipalName'
	Conversion = { $_ }
}
Register-ErmIdentityMapping @param

$param = @{
	Type = 'servicePrincipal'
	Name = 'default'
	Priority = 100
	SourceProperty = 'displayName'
	DestinationProperty = 'displayName'
	Conversion = { $_ }
}
Register-ErmIdentityMapping @param

$param = @{
	Type = 'servicePrincipal'
	Name = 'byID'
	Priority = 99
	SourceProperty = 'id'
	DestinationProperty = 'id'
	Conversion = {
		if (-not $global:spnIDMap) { return }
		$global:spnIDMap[$_]
	}
}
Register-ErmIdentityMapping @param