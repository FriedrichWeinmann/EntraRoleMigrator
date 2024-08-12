function Assert-ErmConnection
{
<#
	.SYNOPSIS
		Asserts a connection has been established.
	
	.DESCRIPTION
		Asserts a connection has been established.
		Fails the calling command in a terminating exception if not connected yet.
		
	.PARAMETER Service
		The service to which a connection needs to be established.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command.
		Used to execute the terminating exception in the caller scope if needed.
	
	.EXAMPLE
		PS C:\> Assert-ErmConnection -Service 'Source' -Cmdlet $PSCmdlet
	
		Silently does nothing if already connected to the source tenant.
		Kills the calling command if not yet connected.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[ValidateSet('Source', 'Destination')]
		[string]
		$Service,
		
		[Parameter(Mandatory = $true)]
		$Cmdlet
	)
	
	process
	{
		if (Get-EntraToken -Service "Graph-EntraRoleMigrator-$Service") { return }
		
		$message = "Not connected yet! Use Connect-ErmService to establish a connection to '$Service' first."
		Invoke-TerminatingException -Cmdlet $Cmdlet -Message $message -Category ConnectionError
	}
}