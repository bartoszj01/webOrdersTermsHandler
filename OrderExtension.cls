/**
 * @name OrderExtension
 * @description This class is provided for you to facilitate the Super Badge
**/
public class OrderExtension {

    public Order orderRecord {get;set;}
    public List<OrderItem> orderItemList {get;set;}
    public String selectedFamily {get;set;}
    public List<chartHelper.chartData> pieData {get;set;}
    public Decimal total {get;set;}

    public Map<Id,OrderItem> orderItemMap;
    ApexPages.StandardSetController standardSetController;

    public OrderExtension(ApexPages.StandardController standardController){
        orderRecord = (Order)standardController.getRecord();
        orderItemMap = new Map<id,OrderItem>();
        if ( orderRecord.Id != null ){
            orderRecord = queryOrderRecord(orderRecord.Id);
        }
    }

    //ToDo: Implement your own method to populate orderItemList
    public List<OrderItem> getorderItemList() {
        orderItemList = new List<orderItem>();
        List<PriceBookEntry> pbeList = [SELECT Product2.Family, Product2.Id, UnitPrice, Product2.Quantity_Remaining__c FROM
                                       	PriceBookEntry WHERE Product2.IsActive = true ];
  		
        //List<OrderItem> oList = new List<OrderItem>();
        for(PriceBookEntry pbe : pbeList) {
            OrderItem o = new OrderItem();        
            o.Quantity = 0;
			o.Product2Id = pbe.Product2Id;
			o.UnitPrice = pbe.UnitPrice;
			orderItemList.add(o);
        }  
        return orderItemList;
    }
    //  that you will call after pagination and/or family selection


    /**
     * @name OnFieldChange
     * @description
    **/
    public void OnFieldChange(){
        //ToDo: Implement logic to store the values changed on the page
        //      and populate pieData
        //      and populate total

    }

    /**
     * @name SelectFamily
     * @description
    **/
    public void SelectFamily(){
        //ToDo: Implement logic to filter based on the selected product family
        getOrderItemList();
    }

    /**
     * @name Save
     * @description
    **/
    public void Save(){
        //ToDo: Implement logic to save the Order and populated OrderItems
        

    }


    /**
     * @name First
     * @description
    **/
    public void First(){

    }


    /**
     * @name Next
     * @description
    **/
    public void Next(){

    }


    /**
     * @name Previous
     * @description
    **/
    public void Previous(){

    }

    /**
     * @name Last
     * @description
    **/
    public void Last(){

    }

    /**
     * @name GetHasPrevious
     * @description
    **/
    public Boolean GetHasPrevious(){
        return null;
    }

    /**
     * @name GetHasNext
     * @description
    **/
    public Boolean GetHasNext(){
        return null;
    }

    /**
     * @name GetTotalPages
     * @description
    **/
    public Integer GetTotalPages(){
        return null;
    }

    /**
     * @name GetPageNumber
     * @description
    **/
    public Integer GetPageNumber(){
        return null;
    }

    /**
     * @name GetFamilyOptions
     * @description
    **/
    public List<SelectOption> GetFamilyOptions(){
        return null;
    }

    /**
     * @name QueryOrderRecord
     * @description
    **/
    public static Order QueryOrderRecord(Id orderId){
        return [
            SELECT Id, AccountId, EffectiveDate, Name, Status, Pricebook2Id,
                (
                    SELECT Id, OrderId, Quantity, UnitPrice, PricebookEntryId, Product2Id,
                         Product2.Name, Product2.Family, Product2.Quantity_Remaining__c
                    FROM OrderItems
                )
            FROM Order
            WHERE Id = :orderId
        ];
    }

}