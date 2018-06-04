@isTest
public class webOrdersTermsHandler_Test {
    
    @isTest
    public static void test1() {
    	// create terms and conditions
        List<TermsAndConditions__c> tncList = new List<TermsAndConditions__c>();
        TermsAndConditions__c t1 = new TermsAndConditions__c();
        t1.Current__c = true;
        t1.Name = 'tnc1';
        t1.Type__c = 'AGB Solandeo';
        t1.Language__c = 'German';
        tncList.add(t1);
        
        TermsAndConditions__c t2 = new TermsAndConditions__c();
        t2.Current__c = true;
        t2.Name = 'tnc2';
        t2.Type__c = 'AGB Discovergy GmbH';
        t2.Language__c = 'German';
        tncList.add(t2);
        
        TermsAndConditions__c t3 = new TermsAndConditions__c();
        t3.Current__c = true;
        t3.Name = 'tnc2';
        t3.Type__c = 'AGBs eServices';
        t3.Language__c = 'German';
        tncList.add(t3);
        
        TermsAndConditions__c t4 = new TermsAndConditions__c();
        t4.Current__c = true;
        t4.Name = 'tnc4';
        t4.Type__c = 'Widerrufsbelehrung eServices';
        t4.Language__c = 'German';
        tncList.add(t4);
        
        // this TnC is not relevant - created to check that only relevant junction objects are created
        TermsAndConditions__c t5 = new TermsAndConditions__c();
        t5.Current__c = true;
        t5.Name = 'tnc5';
        t5.Type__c = 'AGB Verbraucher';
        t5.Language__c = 'German';
        tncList.add(t5);
        
        insert tncList;
        
        List<Attachment> attlist = new List<Attachment>();
        for (TermsAndConditions__c tn : tncList) {
            Attachment a = new Attachment();
            a.Name = tn.Name;
            Blob body = Blob.valueOf('tncBody');
            a.Body = Blob.valueOf(EncodingUtil.base64Encode(body));
            a.ParentId = tn.Id;
            attList.add(a);
        }
        insert attList;

        
        // create opportunities
        List<Opportunity> oppList = new List<Opportunity>();
        
        // web order with 4 accepted
        Opportunity o = new Opportunity();
        o.Name = 'webOrder 1';
        o.RecordTypeId = '0121o000000LUy8';
        o.StageName = 'New';
        o.CloseDate = Date.today() + 90;
        o.OrderSource__c = '{ "type": "Order", "id": "bbe7c4d5-b765-4a53-98ad-2bce5454962d", "version": 1, "createdAt": "2018-06-01T09:55:55.525Z", "lastModifiedAt": "2018-06-01T09:55:55.525Z", "totalPrice": { }, "taxedPrice": { }, "orderState": "Open", "syncInfo": [], "returnInfo": [], "taxMode": "Disabled", "inventoryMode": "None", "taxRoundingMode": "HalfEven", "taxCalculationMode": "LineItemLevel", "origin": "Customer", "lineItems": [ ], "customLineItems": [], "transactionFee": true, "discountCodes": [], "lastMessageSequenceNumber": 1, "cart": { "typeId": "cart", "id": "1c9a6ec0-7293-4795-8842-5c2dddb9b7bf" }, "custom": { "type": { "typeId": "type", "id": "b5673dbe-055b-44bf-ab79-48629089e724" }, "fields": { "cWithdrawal": true, "cTermsAndConditionSolandeo": true, "cTermsAndConditionDiscovergy": true, "cTermsAndConditionSonnen": true, "cPaymentIban": "123456", "cPaymentBic": "123456", "cPaymentName": "Testerin Test" } }, "shippingAddress": { "title": "Dr.", "salutation": "Mr.", "firstName": "Test", "lastName": "Test", "streetName": "Jakobstr.", "streetNumber": "15", "postalCode": "44789", "city": "Bochum", "country": "DE", "company": "Testfirma", "phone": "555", "email": "test@test.de" }, "billingAddress": { "title": "Dr.", "salutation": "Ms.", "firstName": "Testerin", "lastName": "Test", "streetName": "Testweg", "streetNumber": "1", "postalCode": "56789", "city": "Testdorf", "country": "AT", "company": "Testfirma" }, "itemShippingAddresses": [] }';
        oppList.add(o);
        
        // weborder with 2 accepted
        Opportunity o1 = new Opportunity();
        o1.Name = 'webOrder 2';
        o1.RecordTypeId = '0121o000000LUy8';
        o1.StageName = 'New';
        o1.CloseDate = Date.today() + 90;
        o1.OrderSource__c = '{ "type": "Order", "id": "bbe7c4d5-b765-4a53-98ad-2bce5454962d", "version": 1, "createdAt": "2018-06-01T09:55:55.525Z", "lastModifiedAt": "2018-06-01T09:55:55.525Z", "totalPrice": { }, "taxedPrice": { }, "orderState": "Open", "syncInfo": [], "returnInfo": [], "taxMode": "Disabled", "inventoryMode": "None", "taxRoundingMode": "HalfEven", "taxCalculationMode": "LineItemLevel", "origin": "Customer", "lineItems": [ ], "customLineItems": [], "transactionFee": true, "discountCodes": [], "lastMessageSequenceNumber": 1, "cart": { "typeId": "cart", "id": "1c9a6ec0-7293-4795-8842-5c2dddb9b7bf" }, "custom": { "type": { "typeId": "type", "id": "b5673dbe-055b-44bf-ab79-48629089e724" }, "fields": { "cWithdrawal": true, "cTermsAndConditionSolandeo": false, "cTermsAndConditionDiscovergy": false, "cTermsAndConditionSonnen": true, "cPaymentIban": "123456", "cPaymentBic": "123456", "cPaymentName": "Testerin Test" } }, "shippingAddress": { "title": "Dr.", "salutation": "Mr.", "firstName": "Test", "lastName": "Test", "streetName": "Jakobstr.", "streetNumber": "15", "postalCode": "44789", "city": "Bochum", "country": "DE", "company": "Testfirma", "phone": "555", "email": "test@test.de" }, "billingAddress": { "title": "Dr.", "salutation": "Ms.", "firstName": "Testerin", "lastName": "Test", "streetName": "Testweg", "streetNumber": "1", "postalCode": "56789", "city": "Testdorf", "country": "AT", "company": "Testfirma" }, "itemShippingAddresses": [] }';
        oppList.add(o1);
        
        // weborder without orderSource
        Opportunity o2 = new Opportunity();
        o2.Name = 'webOrder 3';
        o2.RecordTypeId = '0121o000000LUy8';
        o2.StageName = 'New';
        o2.CloseDate = Date.today() + 90;
        oppList.add(o2);
        
        // not a weborder - created to check that the process only triggers for weborders
        Opportunity o3 = new Opportunity();
        o3.Name = 'webOrder 4';
        o3.RecordTypeId = '01224000000gOyhAAE';
        o3.StageName = 'New';
        o3.CloseDate = Date.today() + 90;
        oppList.add(o3);
               
        insert oppList;
        
        // assert if trigger has created the TnCsOpportunity
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
        for (Opportunity opp : oppList) {
            newMap.put(o.Id, o);
        }
        webOrdersTermsHanlder wb = new webOrdersTermsHanlder(oppList);
        wb.createAcceptObjects();
        
        System.assertEquals(4, [SELECT Opportunity__c FROM TnCsOpportunity__c WHERE Opportunity__r.Name = 'webOrder 1'].size());
        System.assertEquals(4, [SELECT Id FROM TnCsOpportunity__c WHERE Opportunity__r.Name = 'webOrder 1' AND Accepted__c = true].size());
        System.assertEquals(4, [SELECT Opportunity__c FROM TnCsOpportunity__c WHERE Opportunity__r.Name = 'webOrder 2'].size());
        System.assertEquals(2, [SELECT Id FROM TnCsOpportunity__c WHERE Opportunity__r.Name = 'webOrder 2' AND Accepted__c = true].size());
        System.assertEquals(0, [SELECT Opportunity__c FROM TnCsOpportunity__c WHERE Opportunity__r.Name = 'webOrder 4'].size());
    }
}