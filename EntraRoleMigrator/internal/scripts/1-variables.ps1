# The Different ways Test Results will show their "Changes" column
$script:_ResultDisplayStyles = New-PSFHashtable -DefaultValue {
	if (-not $this.Changes) { return $this.Destination }
	$this.Changes -join ', '
}

# Contains the logic to match identities from source to desintation tenant.
# Used when resolving intended Role Memberships
$script:_IdentityMapping = @{ }