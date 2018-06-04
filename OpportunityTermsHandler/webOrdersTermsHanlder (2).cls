public class webOrdersTermsHanlder {
	
    private List<Opportunity> webOrders;
    private Map<String, String> typeMapping; // map created from static resource, containing tnc name from the order api as key and tnc type as saved in Salesforce as value
	private Map<String, Id> typeIds;
    private Map<Id, DateTime> dateAcceptedMap; // map of Id as key and DateTime as value
    
    public webOrdersTermsHanlder(List<Opportunity> opps) {     
        createTypeMapping();        
        
        this.webOrders = new List<Opportunity>();
        for(Opportunity o : opps) {
            if (o.RecordTypeId == '0121o000000LUy8' && o.OrderSource__c != null) { // web order opportunity id
                webOrders.add(o);
            }
        }
    }
    
    private void createTypeMapping() {
        // get static resource where Mapping of webOrder values are mapped to terms and conditions types
        StaticResource sr = [SELECT Body FROM StaticResource WHERE Name = 'TnCsMappingWebOrder'];
        
        String bodyString = sr.Body.toString();
        this.typeMapping = (Map<String, String>) JSON.deserialize(bodyString, Map<String, String>.class);
    }
    
    public void createAcceptObjects() {
        
        Map<String, Id> idMap = new Map<String, Id>(); // map to hold TnC type as key and its Id as value
        Map<Id, Map<String, Boolean>> acceptMap = createAcceptMap();      
        List<TermsAndConditions__c> tncs = [SELECT Id, Type__c FROM TermsAndConditions__c WHERE Current__c = true AND Type__c IN :typeMapping.values()];
        for (TermsAndConditions__c tnc : tncs) {
            idMap.put(tnc.Type__c, tnc.Id);
        }
        
        // create the records
        List<TnCsOpportunity__c> objList = new List<TnCsOpportunity__c>();
        for (Id i : acceptMap.keySet()) {
            Map<String, Boolean> acceptMapOpp = acceptMap.get(i); // map of Tnc acceptance for the specific opportunity
            for (String type : acceptMapOpp.keySet()) {
                TnCsOpportunity__c tnx = new TnCsOpportunity__c();
                tnx.Opportunity__c = i;
                tnx.TermsAndConditions__c = idMap.get(type);
                tnx.Accepted__c = acceptMapOpp.get(type);
                tnx.DateAccepted__c = dateAcceptedMap.get(i);
                objList.add(tnx);
            }           
        }
        insert objList;
    }
    
    private Map<Id, Map<String, Boolean>> createAcceptMap() {

		Map<Id, Map<String, Boolean>> acceptMap = new Map<Id, Map<String, Boolean>>(); // opp Id as key, Map of tnc type and boolean as value
        this.dateAcceptedMap = new Map<Id, DateTime>();
        
        for (Opportunity o : webOrders) {
            
            // deserialize order source to get the desired object
            String s = o.OrderSource__c;
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(s);
            System.debug(m.get('custom'));
            System.debug(m.get('createdAt'));
            
            DateTime dateAccepted = (DateTime) JSON.deserialize('"'+m.get('createdAt')+'"', DateTime.class);
            System.debug(dateAccepted);
            dateAcceptedMap.put(o.Id, dateAccepted);

            Map<String, Object> m2 = (Map<String, Object>) m.get('custom');
            System.debug(m2.get('fields'));
            
            Map<String, Object> m3 = (Map<String, Object>) m2.get('fields');
            System.debug(m3);
            
            Map<String, Boolean> acceptanceMap = new Map<String, Boolean>(); // tnc type as key, acceptance as value
            for (String str : m3.keySet()) {
                if (str == 'cTermsAndConditionDiscovergy' || str == 'cTermsAndConditionSolandeo' || str == 'cTermsAndConditionSonnen' || str == 'cWithdrawal') {
                    acceptanceMap.put(typeMapping.get(str), (Boolean) m3.get(str));
                }    
            }
            System.debug('acceptanceMap: '+acceptanceMap);
            acceptMap.put(o.Id, acceptanceMap);
            
        }
        return acceptMap;
    }
}