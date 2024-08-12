# Permissions Needed

Different actions of this module require different sets of permission scopes & Role Rights.

+ Scopes: Graph API Permissions that need to be granted to the application authenticated to.
+ Role Rights: The least actual rights the account used must have at a minimum. In delegate auth mode that's the user, in application mode that's the service principal that must have that right.
+ Default Role: The least privileged builtin default role that has the Role Rights needed.

## Get-ErmRole / Test-ErmRole / Invoke-ErmRole (Source)

> [API Reference](https://learn.microsoft.com/en-us/graph/api/rbacapplication-list-roledefinitions)

Scopes:

+ Delegate: `RoleManagement.Read.Directory`
+ Application: `RoleManagement.Read.Directory`

Role Rights:

+ `microsoft.directory/roleDefinitions/standard/read`

Default Roles:

+ Directory Readers

## Invoke-ErmRole (Destination)

> [API Reference](https://learn.microsoft.com/en-us/graph/api/rbacapplication-post-roledefinitions)

Scopes:

+ Delegate: `RoleManagement.ReadWrite.Directory`
+ Application: `RoleManagement.ReadWrite.Directory`

Role Rights:

+ `microsoft.directory/roleDefinitions/allProperties/allTasks`

Default Roles:

+ Privileged Role Administrator

## Get-ErmRoleMember

> [API Reference](https://learn.microsoft.com/en-us/graph/api/rbacapplication-list-roleassignments)

Scopes:

+ Delegate: `RoleManagement.Read.Directory`, `RoleAssignmentSchedule.ReadWrite.Directory`, `RoleEligibilitySchedule.ReadWrite.Directory`, `User.Read.All`, `Application.Read.All`
+ Application: `RoleManagement.Read.Directory`, `RoleAssignmentSchedule.ReadWrite.Directory`, `RoleEligibilitySchedule.ReadWrite.Directory`, `User.Read.All`, `Application.Read.All`

> Note: ReadWrite rights are currently needed for schedule requests, even if read-only.

Role Rights:

+ `microsoft.directory/roleAssignments/standard/read`

Default Roles:

+ Directory Readers

## Test-ErmRoleMember

> [API Reference](https://learn.microsoft.com/en-us/graph/api/rbacapplication-list-roleassignments)

Scopes:

+ Delegate: `RoleManagement.Read.Directory`, `User.Read.All`, `Application.Read.All`
+ Application: `RoleManagement.Read.Directory`, `User.Read.All`, `Application.Read.All`

Role Rights:

+ `microsoft.directory/roleAssignments/standard/read`

Default Roles:

+ Directory Readers

## Invoke-ErmRoleMember (Destination)

This command internally may call `Test-ErmRoleMember` if not provided specific test results already.
See related sections to verify permissions needed for that.

> API Reference: Role Assignments - [Create](https://learn.microsoft.com/en-us/graph/api/rbacapplication-post-roleassignments) / [Delete](https://learn.microsoft.com/en-us/graph/api/unifiedroleassignment-delete)
> [API Reference: Eligibility Schedule Requests](https://learn.microsoft.com/en-us/graph/api/rbacapplication-post-roleeligibilityschedulerequests)
> [API Reference: Assignment Schedule Requests](https://learn.microsoft.com/en-us/graph/api/rbacapplication-post-roleassignmentschedulerequests)

Scopes:

+ Delegate: `Group.Read.All`, `RoleManagement.ReadWrite.Directory`, `RoleEligibilitySchedule.ReadWrite.Directory`, `RoleAssignmentSchedule.ReadWrite.Directory`
+ Application: `Group.Read.All`, `RoleManagement.ReadWrite.Directory`, `RoleEligibilitySchedule.ReadWrite.Directory`, `RoleAssignmentSchedule.ReadWrite.Directory`

Role Rights:

+ `microsoft.directory/roleAssignments/allProperties/allTasks`

Default Roles:

+ Privileged Role Administrator
