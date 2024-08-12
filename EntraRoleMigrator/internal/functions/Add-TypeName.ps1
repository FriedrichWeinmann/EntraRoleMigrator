function Add-TypeName {
	<#
	.SYNOPSIS
		Helper function that adds a name to the inputobject.
	
	.DESCRIPTION
		Helper function that adds a name to the inputobject.
		Useful to add custom formatting rules to an object.
	
	.PARAMETER Name
		The name to add to the object.
	
	.PARAMETER InputObject
		The object to name.
	
	.EXAMPLE
		PS C:\> Get-ChildItem -File | Add-TypeName -Name 'MyModule.File'

		Retrieves all files in the current folder and adds the name "MyModule.File" to each of the result objects.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)
	process {
		if ($null -eq $InputObject) { return }
		$InputObject.PSObject.TypeNames.Insert(0, $Name)
		$InputObject
	}
}