//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @description Test trigger for issue #938. Mimics a subscriber-org User trigger that inserts
 *              GroupMember (a setup object) synchronously in the same transaction as the User insert.
 *              Any Nebula Logger test that inserts a User and then does DML on a non-setup object
 *              (e.g. LoggerScenario__c) in the same transaction will hit MIXED_DML_OPERATION unless
 *              the test wraps its non-setup DML in System.runAs(...).
 *
 *              This is only used in Nebula Logger's pipeline, it's not included in the package (or at least, it shouldn't be!)
 *
 *              Also, since this is only used in the pipeline, a lot best practices (like not putting code directly into triggers)
 *              are intentionally being disregarded ^_^
 */
trigger User_Logger_Mixed_DML_Example on User(after insert) {
  List<Schema.Group> matchingGroups = [SELECT Id FROM Group WHERE DeveloperName = 'Logger_Mixed_DML_Test_Group' AND Type = 'Regular' LIMIT 1];
  if (matchingGroups.isEmpty()) {
    return;
  }

  Id targetGroupId = matchingGroups.get(0).Id;
  List<Schema.GroupMember> newGroupMembers = new List<Schema.GroupMember>();
  for (Schema.User insertedUser : Trigger.new) {
    newGroupMembers.add(new Schema.GroupMember(GroupId = targetGroupId, UserOrGroupId = insertedUser.Id));
  }
  insert newGroupMembers;
}
