public without sharing class LoggerCache {
    private static final String LOGGER_CACHE_PARTITION_NAME = Namespace.getNamespaceWithDotNotation() + 'LoggerCache';
    private static final Cache.OrgPartition ORG_PARTITION = Cache.Org.getPartition(LOGGER_CACHE_PARTITION_NAME);
    private static final Cache.SessionPartition SESSION_PARTITION = Cache.Session.getPartition(
        LOGGER_CACHE_PARTITION_NAME
    );

    private static final Boolean CACHE_IS_IMMUTABLE = true;
    private static final Integer CACHE_TTL_SECS = 3600;
    private static final Cache.Visibility CACHE_VISIBILITY = Cache.Visibility.ALL;

    // Public static methods
    public static void initializeOrgCache() {
        cacheOrganization();
        cacheNetworks();
        cacheUserLicenses();
        cacheProfiles();
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

    public static Map<Id, SObject> cacheNetworks() {
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
        Database.QueryLocator userLicenseQuery = Database.getQueryLocator([SELECT Id, Name FROM UserLicense]);

        Map<Id, UserLicense> userLicensesById = new Map<Id, UserLicense>();
        for (UserLicense userLicense : Database.query(userLicenseQuery.getQuery())) {
            ORG_PARTITION.put(userLicense.Id, userLicense, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
            userLicensesById.put(userLicense.Id, userLicense);
        }
        return userLicensesById;
    }

    private static Map<Id, Profile> cacheProfiles() {
        Database.QueryLocator profileQuery = Database.getQueryLocator([SELECT Id, Name FROM Profile]);

        Map<Id, Profile> profilesById = new Map<Id, Profile>();
        for (Profile profile : Database.query(profileQuery.getQuery())) {
            ORG_PARTITION.put(profile.Id, profile, CACHE_TTL_SECS, CACHE_VISIBILITY, CACHE_IS_IMMUTABLE);
            profilesById.put(profile.Id, profile);
        }
        return profilesById;
    }
}
