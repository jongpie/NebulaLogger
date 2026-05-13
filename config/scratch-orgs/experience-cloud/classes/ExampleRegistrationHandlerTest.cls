@IsTest
private class ExampleRegistrationHandlerTest {
  @IsTest
  static void createUser_returnsExistingUser_whenFederationIdentifierMatches() {
    Schema.User existingUser = createInternalUser('fed-match@example.com', 'fed-match-1');
    Auth.UserData userData = makeUserData('fed-match-1', 'Someone', 'Else', 'FED-MATCH@EXAMPLE.COM');

    System.Test.startTest();
    Schema.User result = new ExampleRegistrationHandler().createUser(null, userData);
    System.Test.stopTest();

    System.assertEquals(existingUser.Id, result.Id, 'Expected existing user to be returned by federation identifier.');
  }

  @IsTest
  static void createUser_returnsExistingUser_whenEmailMatches() {
    Schema.User existingUser = createInternalUser('email-match@example.com', null);
    Auth.UserData userData = makeUserData(null, 'Another', 'Person', 'EMAIL-MATCH@EXAMPLE.COM');

    System.Test.startTest();
    Schema.User result = new ExampleRegistrationHandler().createUser(null, userData);
    System.Test.stopTest();

    System.assertEquals(existingUser.Id, result.Id, 'Expected existing user to be returned by email fallback.');
  }

  @IsTest
  static void updateUser_updatesMappedFields() {
    Schema.User existingUser = createInternalUser('update-me@example.com', null);
    Auth.UserData updatedData = makeUserData('updated-federation-id', 'UpdatedFirst', 'UpdatedLast', 'updated@example.com');

    System.Test.startTest();
    new ExampleRegistrationHandler().updateUser(existingUser.Id, null, updatedData);
    System.Test.stopTest();

    Schema.User actualUser = [
      SELECT Email, FirstName, LastName, FederationIdentifier
      FROM User
      WHERE Id = :existingUser.Id
    ];

    System.assertEquals('updated@example.com', actualUser.Email);
    System.assertEquals('UpdatedFirst', actualUser.FirstName);
    System.assertEquals('UpdatedLast', actualUser.LastName);
    System.assertEquals('updated-federation-id', actualUser.FederationIdentifier);
  }

  private static Auth.UserData makeUserData(String identifier, String firstName, String lastName, String email) {
    Map<String, String> attributeMap = new Map<String, String>();
    return new Auth.UserData(
      identifier,
      firstName,
      lastName,
      firstName + ' ' + lastName,
      email,
      null,
      email,
      'en_US',
      'Google',
      null,
      attributeMap
    );
  }

  private static Schema.User createInternalUser(String email, String federationIdentifier) {
    String timestamp = String.valueOf(DateTime.now().getTime());
    String username = 'example.handler.' + timestamp + '.' + Math.abs(Crypto.getRandomInteger()) + '@example.invalid';
    Id currentUserProfileId = [SELECT ProfileId FROM User WHERE Id = :System.UserInfo.getUserId()].ProfileId;

    Schema.User userToInsert = new Schema.User(
      ProfileId = currentUserProfileId,
      Username = username,
      Email = email,
      LastName = 'Test User',
      Alias = 'tuser',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      FederationIdentifier = federationIdentifier
    );
    insert userToInsert;
    return userToInsert;
  }
}
