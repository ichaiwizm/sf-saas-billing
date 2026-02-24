Account acc = new Account(Name = 'Acme Corp');
insert acc;

Subscription__c sub1 = new Subscription__c(
    Account__c = acc.Id,
    Status__c = 'Active',
    Start_Date__c = Date.newInstance(2026, 1, 1),
    End_Date__c = Date.newInstance(2026, 12, 31),
    Monthly_Amount__c = 99.00
);
insert sub1;

Subscription__c sub2 = new Subscription__c(
    Account__c = acc.Id,
    Status__c = 'Draft',
    Start_Date__c = Date.newInstance(2026, 6, 1),
    End_Date__c = Date.newInstance(2027, 5, 31),
    Monthly_Amount__c = 149.00
);
insert sub2;

List<Invoice__c> invoices = new List<Invoice__c>();
invoices.add(new Invoice__c(
    Subscription__c = sub1.Id,
    Amount__c = 99.00,
    Status__c = 'Paid',
    Invoice_Date__c = Date.newInstance(2026, 1, 10)
));
invoices.add(new Invoice__c(
    Subscription__c = sub1.Id,
    Amount__c = 99.00,
    Status__c = 'Paid',
    Invoice_Date__c = Date.newInstance(2026, 2, 10)
));
invoices.add(new Invoice__c(
    Subscription__c = sub1.Id,
    Amount__c = 99.00,
    Status__c = 'Pending',
    Invoice_Date__c = Date.newInstance(2026, 3, 10)
));
insert invoices;

System.debug('Account Id: ' + acc.Id);
System.debug('Done!');
