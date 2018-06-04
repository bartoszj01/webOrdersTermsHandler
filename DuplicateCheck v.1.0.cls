public with sharing class DuplicateCheck {

	private String email;
	private String name;
	private String firstName;
	private String lastName;
	private String postCode;
	private String country;
	private String street;
	private String city;
	private String company;

	public DuplicateCheck(String email, String firstName, String lastName, String postCode, String country, String street, String city, String company) {
		this.email = email;
		this.firstName = firstName;
		this.lastName = lastName;
		this.postCode = postCode;
		this.country = country;
		this.street = street;
		this.city = city;
		this.company = company;
		this.name = firstName + ' ' + lastName;
	}
	public DuplicateCheck(Opportunity opp) {
		this.company = opp.Company__c;
		this.country = opp.Country__c;
		this.street = opp.BillingStreet__c + ' ' + opp.BillingStreetNo__c;
		this.city = opp.BillingCity__c;
		this.email = opp.Email__c;
		this.postCode = opp.BillingPostalCode__c;
		this.firstName = opp.FirstName__c;
		this.lastName = opp.LastName__c;
		this.company = opp.Company__c;
		this.name = firstName + ' ' + lastName;

	}

	public DuplicateCheck(Asset asset) {

	}
	public DuplicateCheck() {
		// only for anonymous test purposes - can be deleted for implementation
	}

	public List<Account> FindMatchingAccount() {
		// the method finds all matching accounts and returns the list

		Set<Id> personAccIds = new Set<Id>();
		List<Account> matchingAccountsList = new List<Account>();

		// find list of matching accounts - private accounts included, as each person account has related automatically created contact
		List<Account> accounts = [SELECT Id, BillingStreet, BillingPostalCode FROM Account WHERE (Name =:name OR Name =:company) AND (BillingCity = :city OR BillingPostalCode = :postCode) 
											AND  Id IN (SELECT AccountId FROM Contact WHERE email =: email)];

		System.debug('accounts: '+accounts);

		return accounts;
	}


	public Id FindBestAccountID() {
		// the method  returns one account id based on additional match criteria
		List<Account> matchingAccounts = FindMatchingAccount();
		Set<Id> accountIdSet = new Set<Id>(); // IDs of matching accounts
		//List<Contract> contracts = new List<Contract>();
		Id recommended;

		// if matchingAccounts contains only one account, return the ID and stop execution
		if (matchingAccounts.size() == 1) {
			recommended = matchingAccounts[0].Id;
		} else if (matchingAccounts.size() == 0) {
			return NULL;

		} else {
			//multiple matches scenario
			for (Account a : matchingAccounts) {
				accountIdSet.add(a.Id);
			}

			// check if any of the returned accounts has contract linked to it - this is most probably the best match
			List<AggregateResult> contractCount = [SELECT AccountId, count(Id) num FROM Contract WHERE AccountId IN :accountIdSet GROUP BY AccountId];
			for (AggregateResult ar : contractCount) {
				if ((Integer) ar.get('num') > 0 && recommended == NULL) {
					recommended = (Id) ar.get('AccountId');
				}
			}

			// if no account with contract check for the exact match in address
			if (recommended == NULL) {

				recommended = MatchingStreet(street, null, matchingAccounts);
				//for (Account a : matchingAccounts) {

				//	if (a.BillingStreet == street) {
				//		recommended = a.Id;
				//	} 
				//}
				if (recommended == NULL) {
					recommended = matchingAccounts[0].Id;
				}
			}
			
		}
		return recommended;
	}

	public Id FindBestAccountID(List<Account> accounts) {
		// the method  returns one account id based on additional match criteria
		List<Account> matchingAccounts = accounts;
		Set<Id> accountIdSet = new Set<Id>(); // IDs of matching accounts
		//List<Contract> contracts = new List<Contract>();
		Id recommended;

		// if matchingAccounts contains only one account, return the ID and stop execution
		if (matchingAccounts.size() == 1) {
			recommended = matchingAccounts[0].Id;
		} else if (matchingAccounts.size() == 0) {
			return NULL;

		} else {
			//multiple matches scenario
			for (Account a : matchingAccounts) {
				accountIdSet.add(a.Id);
			}

			// check if any of the returned accounts has contract linked to it - this is most probably the best match
			List<AggregateResult> contractCount = [SELECT AccountId, count(Id) num FROM Contract WHERE AccountId IN :accountIdSet GROUP BY AccountId];
			for (AggregateResult ar : contractCount) {
				if ((Integer) ar.get('num') > 0 && recommended == NULL) {
					recommended = (Id) ar.get('AccountId');
				}
			}

			// if no account with contract check for the exact match in address
			if (recommended == NULL) {

				recommended = MatchingStreet(street, null, matchingAccounts);
				//for (Account a : matchingAccounts) {

				//	if (a.BillingStreet == street) {
				//		recommended = a.Id;
				//	} 
				//}
				if (recommended == NULL) {
					recommended = matchingAccounts[0].Id;
				}
			}
			
		}
		return recommended;
	}
	//public Id CreateAccount() {
	//	// create new account if findBestAccountId return null - consider adding this logic to find BestAccountId method (?)
	//	DuplicateCheckSetting__mdt cmt = [SELECT RecordTypeIdPersonAccount__c, RecordTypeIdBusinessAccount__c FROM DuplicateCheckSetting__mdt WHERE Label = 'Account'];

	//	Account a = new Account();
	//	a.Name = name;
	//	a.BillingStreet = street;
	//	a.BillingCity = city;
	//	a.BillingPostalCode = postCode;
	//	a.BillingCountry = country;

	//	if (company != NULL) {
	//		a.RecordTypeId = cmt.RecordTypeIdBusinessAccount__c;
	//		a.PrimaryContact__c = NULL;

	//		insert a;
	//		Contact c = new Contact();
	//		c.LastName = name;
	//		c.Email = email;
	//		c.AccountId = a.Id;
	//		insert c;

	//		a.PrimaryContact__c = c.Id;
	//		update a;

	//	}
	//	else {
	//		a.RecordTypeId = cmt.RecordTypeIdPersonAccount__c;
	//		a.PersonEmail = email;
	//		insert a;
	//	}
	
	//	return a.Id;
	//}
	public Id MatchingStreet (String oppBillingStreet, String streetNumber,List<Account> foundAccounts) {

		//Map<Id, Decimal> matchingStreetMap = new Map<Id, Decimal>();
		//Map<Decimal, Id> accIdMap = new Map<Decimal, Id>();  // street matching ratio as 
		Decimal matchingRatio;  // used within loop in the logic
		Decimal finalMatchingRatio = 0;  // final value after the loop is over for the specific account
		Id recommended; // account Id with the best finalMatchingRatio
		String numericOutput; // street number
		
		// assign/extract the number from values passed to the method
		Pattern p = Pattern.compile('[^0-9]');
		if (streetNumber == NULL) {
			numericOutput = p.matcher(oppBillingStreet).replaceAll('');
			System.debug('numeric numericOutput: '+ numericOutput);		
		}
		else {
			numericOutput = streetNumber;
		}

		// match the street
		Pattern p2 = Pattern.compile('[^a-zA-Z .]');
		String textOutput = p2.matcher(oppBillingStreet).replaceAll('');
		System.debug('text output: '+ textOutput);
		List<String>  textOutputArray = textOutput.split('');

		// create map with account as key and matching ratio as as value
		// if number matches, check which string has the best matching ratio
		for (Account a : foundAccounts) {

			// extract street number from the billing street field of the account
			String numberToCheck = p.matcher(a.BillingStreet).replaceAll('');
			//extract street name from the billing street of the account
			String textToCheck = p2.matcher(a.BillingStreet).replaceAll('');
			System.debug(numberToCheck);
			System.debug(textToCheck);
			Decimal matchingCount = 0; // count of matching characters
			// split string to individual character

			if(numberToCheck != numericOutput) {
				// go to next iteration if the street number does not match the target value
				//matchingStreetMap.put(a.Id, matchingCount);
				continue;
			}

			List<String> textToCheckArray = textToCheck.split('');
			System.debug(textToCheckArray);
			for(Integer i=0; i < textOutputArray.size(); i++) {
				
				System.debug(i < textToCheckArray.size() && textToCheckArray[i] == textOutputArray[i]);

				if (i < textToCheckArray.size() && textToCheckArray[i] == textOutputArray[i]) {
					matchingCount = matchingCount + 1;
				}
			}
			System.debug(textOutputArray.size());
			matchingRatio = matchingCount / (Decimal) textOutputArray.size();
			Decimal matchingRatioRounded = matchingRatio.setScale(2);
			//matchingStreetMap.put(a.Id, matchingRatioRounded);

			if (matchingRatio > finalMatchingRatio) {
				finalMatchingRatio = matchingRatio;
				recommended = a.Id;
			}
		}
		//return matchingStreetMap;
		return recommended;
	}
}

//# equal Email address
//# equal FistName and LastName 
//# BillingAddress