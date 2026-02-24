/**
 * @description Test data factory for creating test records.
 * Centralizes test data creation to avoid duplication across test classes.
 */
@IsTest
public class TestDataFactory {

    /**
     * @description Creates and inserts an Account record.
     * @param name Account name
     * @return Inserted Account record
     */
    public static Account createAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    /**
     * @description Creates a Subscription record (not inserted).
     * @param accountId The Account ID
     * @param status Subscription status
     * @param startDate Start date
     * @param endDate End date
     * @param monthlyAmount Monthly amount
     * @return Subscription__c record (not inserted)
     */
    public static Subscription__c buildSubscription(
        Id accountId,
        String status,
        Date startDate,
        Date endDate,
        Decimal monthlyAmount
    ) {
        return new Subscription__c(
            Account__c = accountId,
            Status__c = status,
            Start_Date__c = startDate,
            End_Date__c = endDate,
            Monthly_Amount__c = monthlyAmount
        );
    }

    /**
     * @description Creates and inserts a Subscription record.
     */
    public static Subscription__c createSubscription(
        Id accountId,
        String status,
        Date startDate,
        Date endDate,
        Decimal monthlyAmount
    ) {
        Subscription__c sub = buildSubscription(accountId, status, startDate, endDate, monthlyAmount);
        insert sub;
        return sub;
    }

    /**
     * @description Creates and inserts a Subscription record with an External ID.
     */
    public static Subscription__c createSubscriptionWithExternalId(
        Id accountId,
        String status,
        Date startDate,
        Date endDate,
        Decimal monthlyAmount,
        String externalId
    ) {
        Subscription__c sub = buildSubscription(accountId, status, startDate, endDate, monthlyAmount);
        sub.External_Id__c = externalId;
        insert sub;
        return sub;
    }

    /**
     * @description Creates and inserts an Invoice record.
     */
    public static Invoice__c createInvoice(
        Id subscriptionId,
        Decimal amount,
        String status,
        Date invoiceDate,
        String externalId
    ) {
        Invoice__c inv = new Invoice__c(
            Subscription__c = subscriptionId,
            Amount__c = amount,
            Status__c = status,
            Invoice_Date__c = invoiceDate,
            External_Id__c = externalId
        );
        insert inv;
        return inv;
    }

    /**
     * @description Creates multiple Accounts for bulk testing.
     * @param count Number of Accounts to create
     * @return List of inserted Account records
     */
    public static List<Account> createAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
        return accounts;
    }
}
