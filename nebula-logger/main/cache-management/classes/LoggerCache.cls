public without sharing class LoggerCache {
    private static final String LOGGER_CACHE_PARTITION_NAME = Namespace.getNamespaceWithDotNotation() + 'LoggerCache';
    private static final Cache.OrgPartition ORG_PARTITION = Cache.Org.getPartition(LOGGER_CACHE_PARTITION_NAME);
    private static final Cache.SessionPartition SESSION_PARTITION = Cache.Session.getPartition(
        LOGGER_CACHE_PARTITION_NAME
    );

    private static final Boolean CACHE_IS_IMMUTABLE = true;
    private static final Integer CACHE_TTL_SECS = 86400; // 86,400 seconds == 24 hours
    private static final Cache.Visibility CACHE_VISIBILITY = Cache.Visibility.ALL;

    // Public static methods
    public static void initializeOrgCache() {
        cacheOrganization();
        cacheNetworks();
        cacheUserLicenses();
        cacheProfiles();
        cacheUserRoles();
        cacheUsers();
    }

    public static Organization getOrganization() {
        if (ORG_PARTITION.contains(UserInfo.getOrganizationId())) {
            return (Organization) ORG_PARTITION.get(UserInfo.getOrganizationId());
        } else {
            return cacheOrganization();
        }
    }

    public static SObject getNetwork(Id networkId) {
        if (!networksEnabled()) {
            return null;
        } else if (ORG_PARTITION.contains(networkId)) {
            return (SObject) ORG_PARTITION.get(UserInfo.getOrganizationId());
        } else {
            return cacheNetworks().get(networkId);
        }
    }

    public static UserLicense getUserLicense(Id userLicenseId) {
        if (ORG_PARTITION.contains(userLicenseId)) {
            return (UserLicense) ORG_PARTITION.get(userLicenseId);
        } else {
            return cacheUserLicenses().get(userLicenseId);
        }
    }

    public static Profile getProfile(Id profileId) {
        if (ORG_PARTITION.contains(profileId)) {
            return (Profile) ORG_PARTITION.get(profileId);
        } else {
            return cacheProfiles().get(profileId);
        }
    }

    public static UserRole getUserRole(Id userRoleId) {
        if (ORG_PARTITION.contains(userRoleId)) {
            return (UserRole) ORG_PARTITION.get(userRoleId);
        } else {
            return cacheUserRoles().get(userRoleId);
        }
    }

    public static User getUser(Id userId) {
        if (ORG_PARTITION.contains(userId)) {
            return (User) ORG_PARTITION.get(userId);
        } else {
            return cacheUsers().get(userId);
        }
    }

    // Private static methods
    private static Organization cacheOrganization() {
        Organization organization = [
            SELECT Id, InstanceName, IsSandbox, Name, NamespacePrefix, OrganizationType
            FROM Organization
        ];
        ORG_PARTITION.put(organization.Id, organization, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);

        return organization;
    }

    private static Boolean networksEnabled() {
        return Schema.getGlobalDescribe().containsKey('Network');
    }

    private static Map<Id, SObject> cacheNetworks() {
        // Networks (experience sites/communities) may not be enabled in the org (no Network object), so run everything dynamically
        if (!networksEnabled()) {
            return null;
        }

        String networkQueryString = 'SELECT Id, Name, UrlPathPrefix FROM Network';
        Map<Id, SObject> networksById = new Map<Id, SObject>();
        for (SObject network : Database.query(networkQueryString)) {
            ORG_PARTITION.put(network.Id, network, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
            networksById.put(network.Id, network);
        }
        return networksById;
    }

    private static Map<Id, UserLicense> cacheUserLicenses() {
        Map<Id, UserLicense> userLicensesById = new Map<Id, UserLicense>();
        for (UserLicense userLicense : [SELECT Id, Name FROM UserLicense]) {
            ORG_PARTITION.put(userLicense.Id, userLicense, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
            userLicensesById.put(userLicense.Id, userLicense);
        }
        return userLicensesById;
    }

    private static Map<Id, Profile> cacheProfiles() {
        Map<Id, Profile> profilesById = new Map<Id, Profile>();
        for (Profile profile : [SELECT Id, Name FROM Profile]) {
            ORG_PARTITION.put(profile.Id, profile, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
            profilesById.put(profile.Id, profile);
        }
        return profilesById;
    }

    private static Map<Id, UserRole> cacheUserRoles() {
        Map<Id, UserRole> userRolesById = new Map<Id, UserRole>();
        for (UserRole userRole : [SELECT Id, Name FROM UserRole]) {
            ORG_PARTITION.put(userRole.Id, userRole, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
            userRolesById.put(userRole.Id, userRole);
        }
        return userRolesById;
    }

    private static Map<Id, User> cacheUsers() {
        // Since some orgs may have thousands of users, only cache users that have recently logged in (max 1,000)
        Date recentLoginDate = System.today().addDays(-2);

        Map<Id, User> usersById = new Map<Id, User>();
        for (User user : [
            SELECT Id, Name, ProfileId, UserRoleId, IsActive
            FROM User
            WHERE LastLoginDate >= :recentLoginDate
            ORDER BY LastLoginDate DESC
            LIMIT 1000
        ]) {
            ORG_PARTITION.put(user.Id, user, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
            usersById.put(user.Id, user);
        }
        return usersById;
    }
}
