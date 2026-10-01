Schema.Account a = [SELECT Id FROM Account WHERE Name = 'Acme'];
Logger.info('Account logged by Id', a.Id);
Logger.info('Account logged by SObject', a);
Logger.info('Account logged by List<SObject>', new List<Schema.Account>{ a });
Database.SaveResult result = System.Database.update(a, false);
Logger.info('Account logged by List<Database.SaveResult>', new List<Database.SaveResult>{ result });
Logger.saveLog();