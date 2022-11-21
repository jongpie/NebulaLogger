/**
 * An apex class that updates portal user details.
   Guest users are never able to access this page.
 */
public with sharing class MyProfilePageController {
    private User user;
    private boolean isEdit = false;

    public User getUser() {
        return user;
    }

    public MyProfilePageController() {
        user = [
            SELECT
                id,
                email,
                username,
                usertype,
                communitynickname,
                timezonesidkey,
                languagelocalekey,
                firstname,
                lastname,
                phone,
                title,
                street,
                city,
                country,
                postalcode,
                state,
                localesidkey,
                mobilephone,
                extension,
                fax,
                contact.email
            FROM User
            WHERE id = :UserInfo.getUserId()
        ];
        // guest users should never be able to access this page
        if (user.usertype == 'GUEST') {
            throw new NoAccessException();
        }
    }

    public Boolean getIsEdit() {
        return isEdit;
    }

    public void edit() {
        isEdit = true;
    }

    public void save() {
        try {
            update user;
            isEdit = false;
        } catch (DmlException e) {
            ApexPages.addMessages(e);
        }
    }

    public PageReference changePassword() {
        return Page.ChangePassword;
    }

    public void cancel() {
        isEdit = false;
        user = [
            SELECT
                id,
                email,
                username,
                communitynickname,
                timezonesidkey,
                languagelocalekey,
                firstname,
                lastname,
                phone,
                title,
                street,
                city,
                country,
                postalcode,
                state,
                localesidkey,
                mobilephone,
                extension,
                fax,
                contact.email
            FROM User
            WHERE id = :UserInfo.getUserId()
        ];
    }
}
