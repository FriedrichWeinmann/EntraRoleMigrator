# Entra Role Migrator

Welcome to the landing page for the PowerShell-based toolkit to help migrate roles in Entra (what was once known as Azure Active Directory) from one Azure tenant to another.

## Installation

This is a PowerShell module, distributed via the [PowerShell Gallery](https://www.powershellgallery.com).
You _can_ manually download the source files, but that might make dependency handling a bit awkward.
Your call.

If you are willing to use the gallery, this is the one-liner that will get you set up:

```powershell
Install-Module EntraRoleMigrator -Scope CurrentUser
```

## Preparation: Rights

Alright, now to get this whole thing to work, we need to configure a few things in both the source and destination tenants of our intended role configuration replication.

If this is your first time doing so, [there is a guide that will explain the concepts and guide you through them, step by step](https://github.com/FriedrichWeinmann/EntraAuth/blob/master/docs/overview.md).

What we need are two dedicated App Registrations, one in the source tenant, one in the destination one.
Technically we could reuse already existing ones, so long as the API Permissions work out, but it is generally recommended to create new ones.
Both require a few API Permissions in order to function.
You can find the per-command detailed breakdown [in this document](permissions.md), but here's the summary to just make it all work:

> API Permissions in Source Tenant App Registration

+ `RoleManagement.Read.Directory`
+ `RoleAssignmentSchedule.ReadWrite.Directory`
+ `RoleEligibilitySchedule.ReadWrite.Directory`
+ `Application.Read.All`
+ `Group.Read.All`
+ `User.Read.All`

> API Permissions in Destination Tenant App Registration

+ `RoleManagement.ReadWrite.Directory`
+ `RoleAssignmentSchedule.ReadWrite.Directory`
+ `RoleEligibilitySchedule.ReadWrite.Directory`
+ `Application.Read.All`
+ `Group.Read.All`
+ `User.Read.All`

> Delegate Authentication & Role Requirements

If you intend to use Application authentication for your use of the module, that's it.
If however you are planning to use Delegate authentication instead - probably a good idea, at least to begin with, to prevent unintended side effects - the user account used must be member in the correct roles:

+ Source Tenant: Directory Readers
+ Destination Tenant: Directory Readers, Privileged Role Administrator

## Using the module

> You can find several example scripts in the [examples](examples) subfolder.

The first thing to get started, is to connect to both Source and Destination tenant:

```powershell
Connect-ErmService -Type Source -ClientID $sourceClientID -TenantID $sourceTenantID
Connect-ErmService -Type Destination -ClientID $destClientID -TenantID $destTenantID
```

> "Connect-ErmService" supports a wide range of authentication options, for more details, see the help on the command.

Then we need to tell the module, how principals - users, service principals, ... - should be matched between the source tenant and the destination tenant.
This can be done quite flexibly, but here is a simple example matching based on UserPrincipalName:

```powershell
Register-ErmIdentityMapping -Type user -Name default -Priority 100 -SourceProperty userPrincipalName -DestinationProperty userPrincipalName -Conversion { $_ -replace 'fabrikam.org','contoso.com' }
```

Finally, we are ready to roll:

```powershell
Invoke-ErmRole -Confirm:$false
Invoke-ErmRoleMember -Confirm:$false
```

**STOP!!**

Do not actually just run that.
Or maybe do, but be aware of just what that will do first!

`Invoke-ErmRole` will ensure that all custom roles that exist in the source tenant - and _only_ those - also exist in the destination tenant.
So far so harmless, depending on how the two tenants are configured, `Invoke-ErmRoleMember` could potentially lock you out of your destination tenant!
If none of the existing role memberships match the source tenant, they will all be deleted.

To do less harm, let us first see, what _would_ happen, if we actually _did_ press that button:

```powershell
Test-ErmRole
Test-ErmRoleMember
```

This is going to execute a full test, listing all the changes pending.
With this we can estimate the impact of what we are about to do.
We can also pipe individual result objects of the test commands to the corresponding invoke command to only apply the changes selected:

```powershell
# Gather test results
$test = Test-ErmRoleMember
# Inspect content
$test
# Apply selected changes
$test[1,3,6,7] | Invoke-ErmRoleMember
```
