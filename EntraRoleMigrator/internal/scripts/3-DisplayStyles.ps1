# Role
$script:_ResultDisplayStyles['Role-Delete'] = {
	'Delete: {0}' -f $this.Change.Name
}
$script:_ResultDisplayStyles['Role-Create'] = {
	'Create: {0}' -f $this.Change.Name
}
$script:_ResultDisplayStyles['Role-Update'] = {
	$__items = foreach ($change in $this.Change) {
		switch ($change.Action) {
			'Update' { '{0}: {1}' -f $change.Property, $change.Value }
			'AddRight' { '+{0}' -f $change.Value }
			'RemoveRight' { '-{0}' -f $change.Value }
		}
	}
	$__items -join "`n"
}
$script:_ResultDisplayStyles['Membership-Ignore'] = {
	'Ignore: {0}' -f $this.Change.Value
}
$script:_ResultDisplayStyles['Membership-Update'] = {
	$__items = foreach ($change in $this.Change) {
		switch ($change.Action) {
			'Update' { '{0}: {1}' -f $change.Property, $change.Value }
		}
	}
	$__items -join ', '
}
$script:_ResultDisplayStyles['Membership-Remove'] = { }
$script:_ResultDisplayStyles['Membership-Add'] = { }