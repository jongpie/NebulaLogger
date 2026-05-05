global class ExampleRegistrationHandler implements Auth.RegistrationHandler {
  private static final String LOGGER_SCENARIO = 'Nebula Logger - Experience Cloud testing';

  global Schema.User createUser(Id portalId, Auth.UserData userData) {
    Logger.setScenario(LOGGER_SCENARIO);
    Logger.info(
      new LogMessage('Running custom auth registration handler for portalId {0} with user data:\n\n{1}', portalId, System.JSON.serializePretty(userData))
    );
    Logger.saveLog();

    try {
      Schema.User existingUser = findExistingUser(userData);
      if (existingUser != null) {
        return existingUser;
      }

      Schema.Contact contact = getOrCreateContact(userData);
      Schema.Profile communityProfile = getCommunityProfile();

      String email = normalizeEmail(userData.email);
      String localPart = email != null ? email.substringBefore('@') : 'social.user';
      String timeSuffix = String.valueOf(DateTime.now().getTime());

      Schema.User newUser = new Schema.User(
        Alias = makeAlias(localPart),
        CommunityNickname = makeNickname(localPart, timeSuffix),
        ContactId = contact.Id,
        Email = (email != null ? email : localPart + '+' + timeSuffix + '@example.invalid'),
        EmailEncodingKey = 'UTF-8',
        FederationIdentifier = userData.identifier,
        FirstName = String.isBlank(userData.firstName) ? 'Social' : userData.firstName,
        LanguageLocaleKey = 'en_US',
        LastName = String.isBlank(userData.lastName) ? 'User' : userData.lastName,
        LocaleSidKey = 'en_US',
        ProfileId = communityProfile.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        Username = (email != null ? email : localPart + '.' + timeSuffix + '@example.invalid')
      );

      insert newUser;

      Logger.info('Successfully created new user', newUser);
      Logger.saveLog();

      return newUser;
    } catch (System.Exception ex) {
      Logger.exception('Error trying to create user', ex);
    }
  }

  global void updateUser(Id userId, Id portalId, Auth.UserData userData) {
    Schema.User userToUpdate = new Schema.User(
      Id = userId,
      FirstName = String.isBlank(userData.firstName) ? null : userData.firstName,
      LastName = String.isBlank(userData.lastName) ? null : userData.lastName,
      Email = normalizeEmail(userData.email),
      FederationIdentifier = userData.identifier
    );
    update userToUpdate;
  }

  private static Schema.User findExistingUser(Auth.UserData userData) {
    if (String.isNotBlank(userData.identifier)) {
      List<Schema.User> usersByFederationId = [
        SELECT Id, FederationIdentifier
        FROM User
        WHERE FederationIdentifier = :userData.identifier
        LIMIT 1
      ];
      if (!usersByFederationId.isEmpty()) {
        return usersByFederationId[0];
      }
    }

    String email = normalizeEmail(userData.email);
    if (email != null) {
      List<Schema.User> usersByEmail = [
        SELECT Id, Email
        FROM User
        WHERE Email = :email
        LIMIT 1
      ];
      if (!usersByEmail.isEmpty()) {
        return usersByEmail[0];
      }
    }

    return null;
  }

  private static Schema.Contact getOrCreateContact(Auth.UserData userData) {
    String email = normalizeEmail(userData.email);
    if (email != null) {
      List<Schema.Contact> existingContacts = [
        SELECT Id
        FROM Contact
        WHERE Email = :email
        LIMIT 1
      ];
      if (!existingContacts.isEmpty()) {
        return existingContacts[0];
      }
    }

    Schema.Account account = new Schema.Account(Name = 'Experience Cloud Social Login Users');
    insert account;

    Schema.Contact contact = new Schema.Contact(
      AccountId = account.Id,
      FirstName = String.isBlank(userData.firstName) ? 'Social' : userData.firstName,
      LastName = String.isBlank(userData.lastName) ? 'User' : userData.lastName,
      Email = email
    );
    insert contact;
    return contact;
  }

  private static Schema.Profile getCommunityProfile() {
    Id siteId = Site.getSiteId();
    if (siteId != null) {
      Site currentSite = [SELECT GuestUserId FROM Site WHERE Id = :siteId LIMIT 1];
      if (currentSite.GuestUserId != null) {
        Schema.User guestUser = [
          SELECT Profile.Name
          FROM User
          WHERE Id = :currentSite.GuestUserId
          LIMIT 1
        ];

        String siteNamePrefix = getSiteNamePrefixFromGuestProfileName(guestUser.Profile.Name);
        if (String.isNotBlank(siteNamePrefix)) {
          List<Schema.Profile> siteScopedProfiles = [
            SELECT Id, Name, UserType
            FROM Profile
            WHERE UserType IN ('CSPLitePortal', 'PowerCustomerSuccess', 'CustomerSuccess') AND Name LIKE :siteNamePrefix + '%'
            ORDER BY Name
            LIMIT 1
          ];
          if (!siteScopedProfiles.isEmpty()) {
            return siteScopedProfiles[0];
          }
        }
      }
    }

    List<Schema.Profile> fallbackByNameProfiles = [
      SELECT Id, Name, UserType
      FROM Profile
      WHERE UserType IN ('CSPLitePortal', 'PowerCustomerSuccess', 'CustomerSuccess') AND Name = 'Logger Test Site User Profile'
      LIMIT 1
    ];
    if (!fallbackByNameProfiles.isEmpty()) {
      return fallbackByNameProfiles[0];
    }

    List<Schema.Profile> genericFallbackProfiles = [
      SELECT Id, Name, UserType
      FROM Profile
      WHERE UserType IN ('CSPLitePortal', 'PowerCustomerSuccess', 'CustomerSuccess')
      ORDER BY Name
      LIMIT 1
    ];
    if (genericFallbackProfiles.isEmpty()) {
      throw new System.IllegalArgumentException('No Experience Cloud user profile found. Create/enable a community user profile first.');
    }
    return genericFallbackProfiles[0];
  }

  private static String getSiteNamePrefixFromGuestProfileName(String guestProfileName) {
    if (String.isBlank(guestProfileName)) {
      return null;
    }
    String suffix = ' Guest Profile';
    if (guestProfileName.endsWith(suffix)) {
      return guestProfileName.substring(0, guestProfileName.length() - suffix.length());
    }
    return guestProfileName;
  }

  private static String normalizeEmail(String email) {
    return String.isBlank(email) ? null : email.trim().toLowerCase();
  }

  private static String makeAlias(String value) {
    String cleaned = String.isBlank(value) ? 'socialusr' : value.replaceAll('[^A-Za-z0-9]', '');
    if (cleaned.length() < 2) {
      cleaned = cleaned + 'usr';
    }
    return cleaned.left(8);
  }

  private static String makeNickname(String value, String suffix) {
    String cleaned = String.isBlank(value) ? 'social.user' : value.replaceAll('[^A-Za-z0-9]', '.');
    return (cleaned.left(Math.min(20, cleaned.length())) + '.' + suffix.right(6)).toLowerCase();
  }
}
