/**
 * An apex class that updates details of a portal user.
   Guest users are never able to access this page.
 */
@IsTest
public with sharing class MyProfilePageControllerTest {
  @IsTest(SeeAllData=true)
  static void testSave() {
    // Modify the test to query for a portal user that exists in your org
    List<Schema.User> existingPortalUsers = [SELECT id, profileId, userRoleId FROM User WHERE UserRoleId != NULL AND UserType = 'CustomerSuccess'];

    if (existingPortalUsers.isEmpty()) {
      Schema.User currentUser = [
        SELECT id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country
        FROM User
        WHERE id = :System.UserInfo.getUserId()
      ];
      MyProfilePageController controller = new MyProfilePageController();
      // System.Assert.areEqual(currentUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
      // System.Assert.isTrue(controller.getIsEdit() == false, 'isEdit should default to false');
      controller.edit();
      // System.Assert.isTrue(controller.getIsEdit());
      controller.cancel();
      // System.Assert.isTrue(controller.getIsEdit() == false);

      // System.Assert.isTrue(Page.ChangePassword.getUrl().equals(controller.changePassword().getUrl()));

      String randFax = Math.rint(Math.random() * 1000) + '5551234';
      controller.getUser().Fax = randFax;
      controller.save();
      // System.Assert.isTrue(controller.getIsEdit() == false);

      currentUser = [SELECT id, fax FROM User WHERE id = :currentUser.Id];
      // System.Assert.isTrue(currentUser.fax == randFax);
    } else {
      Schema.User existingPortalUser = existingPortalUsers[0];
      String randFax = Math.rint(Math.random() * 1000) + '5551234';

      System.runAs(existingPortalUser) {
        MyProfilePageController controller = new MyProfilePageController();
        // System.Assert.areEqual(existingPortalUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
        // System.Assert.isTrue(controller.getIsEdit() == false, 'isEdit should default to false');
        controller.edit();
        // System.Assert.isTrue(controller.getIsEdit());

        controller.cancel();
        // System.Assert.isTrue(controller.getIsEdit() == false);

        controller.getUser().Fax = randFax;
        controller.save();
        // System.Assert.isTrue(controller.getIsEdit() == false);
      }

      // verify that the user was updated
      existingPortalUser = [SELECT id, fax FROM User WHERE id = :existingPortalUser.Id];
      // System.Assert.isTrue(existingPortalUser.fax == randFax);
    }
  }
}
