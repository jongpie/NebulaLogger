LogMessage markdownLogMessage = new MarkdownLogMessageBuilder()
  .heading(1, 'Example of an H1 heading')
  .text('Example of logging some markdown in the message field')
  .heading(2, 'Example SObjects Datatable')
  .text('Let\'s display some records & specified fields as a datatable')
  .tableFromSObjects(
    [SELECT Id, Name, Email, ProfileId, Profile.Name, Username FROM User WHERE Id = :System.UserInfo.getUserId()],
    new List<String>{ 'Id', 'Name', 'Email', 'Username', 'ProfileId' }
  )
  .heading(2, 'Example Key-Value Map Datatable')
  .text('Let\'s display a Map<String, Object> as a datatable')
  .kvTable(new Map<String, Object>{ 'someTextKey' => 'My text value', 'someNumberKey' => 30 })
  .heading(2, 'Example JSON')
  .json([SELECT Id, Name, Profile.Name FROM User WHERE Id = :System.UserInfo.getUserId()]);

Logger.info(markdownLogMessage);

Logger.saveLog();