$graphCfg = @{
	Name          = 'Graph-EntraRoleMigrator-Source'
	ServiceUrl    = 'https://graph.microsoft.com/v1.0'
	Resource      = 'https://graph.microsoft.com'
	DefaultScopes = @()
	HelpUrl       = 'https://developer.microsoft.com/en-us/graph/quick-start'
	Header        = @{ 'content-type' = 'application/json' }
}
Register-EntraService @graphCfg

$graphCfg = @{
	Name          = 'Graph-EntraRoleMigrator-Destination'
	ServiceUrl    = 'https://graph.microsoft.com/v1.0'
	Resource      = 'https://graph.microsoft.com'
	DefaultScopes = @()
	HelpUrl       = 'https://developer.microsoft.com/en-us/graph/quick-start'
	Header        = @{ 'content-type' = 'application/json' }
}
Register-EntraService @graphCfg