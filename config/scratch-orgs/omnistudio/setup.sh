# https://github.com/SFDC-Assets/omnistudio-basic-scratchorg/blob/master/orgInit.sh

# sf project deploy start --source-dir ./metadata/

PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'OmniStudioAdmin'];
insert new Schema.PermissionSetAssignment(
  AssigneeId = System.UserInfo.getUserId(),
  PermissionSetId = permissionSet.Id
);
