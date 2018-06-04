public with sharing class  DuplicateCheckHandler2 {

	private List<Opportunity> oppList; // list of opportunities passed e.g. from trigger
	private List<Asset> assetList; // list of opportunities passed e.g. from trigger
	private List<Contact> cList; // list of contacts to insert
	private List<Account> aList; // list of accounts to link primary contact
	private Map<Id, Id> accIdMap; // return map - key value pairs of opportunity IDs passed to the class and corresponding accountIDs which were found or created
	private List<Case> caseList; 
	private Map<Id, Account> oppIdAccMap; //  opportunity Id as key and account to be inserted as value
	private Map<Id, Account> accountsMap; // account Id as key, account record as value - for linking primary contacts
	private List<DuplicateCheckObject> duplicateObjectList; 

	public DuplicateCheckHandler2(List<Opportunity> oppList) {
		this.oppList = oppList;
		generateDuplicateCheckObject();
	}

	public DuplicateCheckHandler2(List<Asset> assetList)  {
		this.assetList = assetList;
		generateDuplicateCheckObject();
	}

	public List<DuplicateCheckObject> generateDuplicateCheckObject() {

		//List<DuplicateCheckObject> duplicateObjectList = new List<DuplicateCheckObject>();
		duplicateObjectList = new List<DuplicateCheckObject>();

		if (oppList != NULL && !oppList.isEmpty()) {
			for (Opportunity o : oppList) {
				if (o.AccountId == NULL) {
					DuplicateCheckObject dco = new DuplicateCheckObject(o);
					duplicateObjectList.add(dco.getDuplicateCheckObject());					
				}

			}		
		}

		else if (assetList != NULL && !assetList.isEmpty()) {
			for (Asset a : assetList) {
				if (a.AccountId == NULL) {
					DuplicateCheckObject dco = new DuplicateCheckObject(a);
					duplicateObjectList.add(dco.getDuplicateCheckObject());				
				}
			}
		}

		return duplicateObjectList;
	}

	public Map<Id, Id> handleObjects() {
		DuplicateCheckSetting__mdt cmt = [SELECT RecordTypeIdPersonAccount__c, RecordTypeIdBusinessAccount__c FROM DuplicateCheckSetting__mdt WHERE Label = 'Account'];
		
		System.debug('duplicateObjectList' + duplicateObjectList);
		caseList = new List<Case>();
		oppIdAccMap =  new Map<Id, Account>();
		accountsMap = new Map<Id, Account>();
		cList = new List<Contact>();
		aList = new List<Account>();
		accIdMap = new Map<Id, Id>();

		Map<Id, List<Account>> oppAccMap = findAccounts();

		for (DuplicateCheckObject dco : duplicateObjectList)  {
		
			List<Account> matchingAccounts = oppAccMap.get(dco.recId);
			
			if (matchingAccounts.isEmpty()) {
				// create new account
				Account a = new Account();
				if (dco.company == NULL) {
					a = initializeNewAccount(dco.firstName, dco.lastName, dco.email, cmt.RecordTypeIdPersonAccount__c, dco.company, dco.city, dco.postCode, dco.street);
				} else {
					a = initializeNewAccount(dco.firstName, dco.lastName, dco.email, cmt.RecordTypeIdBusinessAccount__c, dco.company, dco.city, dco.postCode, dco.street);
				}
				oppIdAccMap.put(dco.recId, a);

				
			} else if (matchingAccounts.size() == 1) {
				// one matching account found, no other action needed
				accIdMap.put(dco.recId, matchingAccounts[0].Id);
			} else {
				// multiple matches found, find the best matching one and add to the return map
				DuplicateCheck dc = new DuplicateCheck(dco.email, dco.firstName, dco.lastName, dco.postCode, dco.country, dco.street, dco.city, dco.company);
				accIdMap.put(dco.recId, dc.FindBestAccountID(matchingAccounts));

				Case cs = new Case();
				// schema check recId what object it is, control statements to assign to correct field
				//cs.OpportunityName__c = o.Id;
				cs.Subject = 'Verify opportunity link with the account';
				cs.Description = 'The Opportunity has been linked with an account, verify if the chosen account was correct';
				caseList.add(cs);
			}

		}
				// insert cases - toDo: add list of accounts to the case
		if (caseList.size() > 0) {
			insert caseList;	
		}
		if (oppIdAccMap.values().size() > 0) {
			insert oppIdAccMap.values();
				
		}

		// add ID pairs of newly created accounts to the return map
		for (Id i : oppIdAccMap.keySet()) {
			accIdMap.put(i, oppIdAccMap.get(i).Id);
			accountsMap.put(oppIdAccMap.get(i).Id, oppIdAccMap.get(i));
		}  

		// create contacts for newly created business accounts
		for (DuplicateCheckObject dco : duplicateObjectList) {
			if (oppIdAccMap.containsKey(dco.recId) && oppIdAccMap.get(dco.recId).RecordTypeId == cmt.RecordTypeIdBusinessAccount__c ) {

				String firstName = dco.firstName;
				String lastName = dco.lastName;
				String email = dco.email;
				Id accountId = oppIdAccMap.get(dco.recId).Id;

				Contact c = initializeContact(accountId, firstName, lastName, email);
				cList.add(c);
			}
		}
		insert cList;

		// loop through the list of inserted contacts and link them as primary contacts to their respective accounts
		for (Contact c : cList) {
			Account a = accountsMap.get(c.accountId);
			a.PrimaryContact__c = c.Id;
			aList.add(a);
		}
		update aList;

		System.debug(accIdMap);
		return accIdMap;		
	}

	public Map<Id, Id> handleOpportunities() {
		DuplicateCheckSetting__mdt cmt = [SELECT RecordTypeIdPersonAccount__c, RecordTypeIdBusinessAccount__c FROM DuplicateCheckSetting__mdt WHERE Label = 'Account'];

		System.debug('oppList' + oppList);
		caseList = new List<Case>();
		oppIdAccMap =  new Map<Id, Account>();
		accountsMap = new Map<Id, Account>();
		cList = new List<Contact>();
		aList = new List<Account>();
		accIdMap = new Map<Id, Id>();

		//**
		Map<Id, List<Account>> oppAccMap = findAccounts();

		for (Opportunity o : oppList)  {
			if (o.AccountId == NULL) {			
				List<Account> matchingAccounts = oppAccMap.get(o.Id);
				
				if (matchingAccounts.isEmpty()) {
					// create new account
					Account a = new Account();
					if (o.Company__c == NULL) {
						a = initializeNewAccount(o.FirstName__c, o.LastName__c, o.Email__c, cmt.RecordTypeIdPersonAccount__c, o.Company__c, o.BillingCity__c, o.BillingPostalCode__c, o.BillingStreet__c);
					} else {
						a = initializeNewAccount(o.FirstName__c, o.LastName__c, o.Email__c, cmt.RecordTypeIdBusinessAccount__c, o.Company__c, o.BillingCity__c, o.BillingPostalCode__c, o.BillingStreet__c);
					}
					oppIdAccMap.put(o.Id, a);

					
				} else if (matchingAccounts.size() == 1) {
					// one matching account found, no other action needed
					accIdMap.put(o.Id, matchingAccounts[0].Id);
				} else {
					// multiple matches found, find the best matching one and add to the return map
					DuplicateCheck dc = new DuplicateCheck(o);
					accIdMap.put(o.Id, dc.FindBestAccountID(matchingAccounts));

					Case cs = new Case();
					cs.OpportunityName__c = o.Id;
					cs.Subject = 'Verify opportunity link with the account';
					cs.Description = 'The Opportunity has been linked with an account, verify if the chosen account was correct';
					caseList.add(cs);
				}
			}
		}
		// insert cases - toDo: add list of accounts to the case
		if (caseList.size() > 0) {
			insert caseList;	
		}
		if (oppIdAccMap.values().size() > 0) {
			insert oppIdAccMap.values();
				
		}

		// add ID pairs of newly created accounts to the return map
		for (Id i : oppIdAccMap.keySet()) {
			accIdMap.put(i, oppIdAccMap.get(i).Id);
			accountsMap.put(oppIdAccMap.get(i).Id, oppIdAccMap.get(i));
		}  

		// create contacts for newly created business accounts
		for (Opportunity o : oppList) {
			if (oppIdAccMap.containsKey(o.Id) && oppIdAccMap.get(o.Id).RecordTypeId == cmt.RecordTypeIdBusinessAccount__c ) {

				String firstName = o.FirstName__c;
				String lastName = o.LastName__c;
				String email = o.Email__c;
				Id accountId = oppIdAccMap.get(o.Id).Id;

				Contact c = initializeContact(accountId, firstName, lastName, email);
				cList.add(c);
			}
		}
		insert cList;

		// loop through the list of inserted contacts and link them as primary contacts to their respective accounts
		for (Contact c : cList) {
			Account a = accountsMap.get(c.accountId);
			a.PrimaryContact__c = c.Id;
			aList.add(a);
		}
		update aList;

		System.debug(accIdMap);
		return accIdMap;
	}
	private Account initializeNewAccount(String firstName, String lastName, String email, String recordTypeId, String company, String billingCity, String billingPostalCode, String billingStreet) {		
		
		Account a = new Account();
		a.BillingStreet = billingStreet;
		a.BillingCity = billingCity;
		a.BillingPostalCode = billingPostalCode;
		a.RecordTypeId = recordTypeId;

		if (company != NULL ) {
			// business account
			a.Name = company;
		}
		else {
			// person account
			a.FirstName = firstName;
			a.LastName = lastName;
			a.PersonEmail = email;
		}
		return a;
	}
	private Contact initializeContact(Id accountId, String firstName, String lastName, String email) {

		Contact c = new Contact();
		c.FirstName = firstName;
		c.LastName = lastName;
		c.Email = email;
		c.AccountId = accountId;
		return c;			
	}
	private Map<Id, List<Account>> findAccounts() {
		// the method searches for accounts and returns a map of recordId to which matching accounts are looked for and the list of matching accounts

		//List<DuplicateCheckObject> duplicateObjectList = generateDuplicateCheckObject();

		Set<String> names = new Set<String>(); // set of all names to query accounts against
		Set<String> cities = new Set<String>();
		Set<String> postalCodes = new Set<String>();
		Set<String> emails = new Set<String>();
		Map<Id, List<Account>> idAccountMap = new Map<Id, List<Account>>(); // the return map - record Id as key, list of potential matching accounts as value

		for (DuplicateCheckObject dco : duplicateObjectList) {

			if (dco.city != NULL) {
				names.add(dco.city);
			}
			if (dco.company != NULL) {
				names.add(dco.company);
			} else if (dco.firstName != NULL && dco.lastName != NULL) {
				String name = dco.firstName + ' ' + dco.lastName;
				names.add(name);
			}
			if (dco.postCode != NULL) {
				postalCodes.add(dco.postCode);
			}
			if (dco.email != NULL) {
				emails.add(dco.email);
			}
		}

		Map<Id, Set<String>> emailsMap = new Map<Id, Set<String>>();

		List<Account> potentialMatch = [SELECT Id, Name, BillingStreet, BillingPostalCode, BillingCity, (SELECT AccountId, Email FROM Contacts WHERE Email IN :emails) FROM Account WHERE Name IN:names AND (BillingCity IN :cities OR 
										BillingPostalCode IN :postalCodes) AND Id IN (SELECT AccountId FROM Contact WHERE Email IN :emails)];

		
		// create map of account id and set of contact email under that account
		for (Account a : potentialMatch) {
			Set<String> cntsSet = new Set<String>();
			List<Contact> cntsList = a.Contacts;

			for (Contact c : cntsList) {
				cntsSet.add(c.Email);
			}		
			emailsMap.put(a.Id, cntsSet);
		}
		System.debug(emailsMap);

		for (DuplicateCheckObject dco : duplicateObjectList) {
			List<Account> newList = new List<Account>();

			for (Account a : potentialMatch) {
				System.debug(emailsMap.get(a.Id));
				System.debug(dco.email);

				if ((a.Name == dco.company || a.Name == dco.firstName + ' ' + dco.lastName) && 
					(a.BillingCity == dco.city || a.BillingPostalCode == dco.postCode) &&
					 emailsMap.get(a.Id).contains(dco.email.toLowerCase())) { 

					newList.add(a);
				}
			}
			idAccountMap.put(dco.recId, newList);
			System.debug(newList);
		}

		return idAccountMap;
	}

}