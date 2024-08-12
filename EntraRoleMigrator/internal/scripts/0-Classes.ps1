$source = @'
namespace EntraRoleMigrator
{
	public enum PrincipalType
	{
		user,
		servicePrincipal
	}
}
'@
if (-not ([System.Management.Automation.PSTypeName]'EntraRoleMigrator.PrincipalType').Type) {
	Add-Type -TypeDefinition $source -ErrorAction Stop
}