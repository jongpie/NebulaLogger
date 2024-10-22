@SuppressWarnings('PMD.ApexCrudViolation, PMD.ApexDoc')
public with sharing class ExampleClassWithLogging {
  public void doSomething() {
    Logger.finest('Starting the doSomething() method!');

    try {
      insertContact('Some Contact Name');
    } catch (Exception ex) {
      Logger.error('An unexpected exception occurred', ex);
      Logger.saveLog();
      throw ex;
    }
  }

  public Schema.Contact insertContact(String contactName) {
    Schema.Contact contact = new Schema.Contact();
    // TODO don't forget to populate the record's required fields
    // before deploying this code to prod!
    insert contact;
    return contact;
  }
}
