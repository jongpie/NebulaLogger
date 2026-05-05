Schema.UserRole userRole = [SELECT Id FROM UserRole LIMIT 1];
update new Schema.User(Id = System.UserInfo.getUserId(), UserRoleId = userRole.Id);