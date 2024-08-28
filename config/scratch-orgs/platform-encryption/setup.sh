# https://salesforce.stackexchange.com/questions/331313/scratch-org-generate-keys-automatically

sf project deploy start --source-dir ./metadata/permissionsets/PlatformEncryptionAdmin.permissionset-meta.xml

PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'PlatformEncryptionAdmin'];
insert new Schema.PermissionSetAssignment(
  AssigneeId = System.UserInfo.getUserId(),
  PermissionSetId = permissionSet.Id
);

sf data create record --sobject TenantSecret --values "Type=EventBus Description='Scratch org event bus encryption key'"

sf project deploy start --source-dir ./metadata/settings/PlatformEncryption.settings-meta.xml
