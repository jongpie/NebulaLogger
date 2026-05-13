Schema.UserRole userRole = [SELECT Id, Name FROM UserRole LIMIT 1];
System.debug('Assigning user role to the current user:\n\n' + System.JSON.serializePretty(userRole));
update new Schema.User(Id = System.UserInfo.getUserId(), UserRoleId = userRole.Id);