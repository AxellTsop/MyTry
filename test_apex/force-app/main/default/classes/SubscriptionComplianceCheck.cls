global class SubscriptionComplianceCheck implements Database.Batchable<sObject> {
    private static final String ELEMENTS_MANQUANTS = 'Éléments manquants';
    private static final String IMMO_NEUF = 'Conformité Immo neuf';
    
    global List<SBQQ__Subscription__c> start(Database.BatchableContext cnx) { 
         return [SELECT Id, CompanyAddressCity__c, CompanyPhone__c, ContactGender__c, ContactLastName__c, 
                 ContactFirstName__c, CompanyName__c, PromoterDescription__c, SBQQ__RequiredById__c,
                 FlowType__c, Souscription_Conforme__c, ComplianceProcess__c, Status__c, 
                 ProductWorkflow__c, CompanyAddressStreet__c, CompanyAddressZipcode__c, LeadPhone__c,
                 ContractEmail__c, CompanySiret__c FROM SBQQ__Subscription__c WHERE Status__c = :ELEMENTS_MANQUANTS
                 AND Souscription_Conforme__c = false];
    }
    
    global void execute(Database.BatchableContext cnx, List<SBQQ__Subscription__c> scope) {
        try {
            List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>();
            for(SBQQ__Subscription__c sub : scope) {
               if (sub.ComplianceProcess__c == IMMO_NEUF) {
                    SBQQ__Subscription__c subImmo = setConformiteImmoNeuf(sub);
                    if (subImmo.MissingInformations__c == 'Conformité Immo neuf') {
                        if (sub.SBQQ__RequiredById__c != null) {
                           setParentConforme(sub.SBQQ__RequiredById__c);
                       }
                    }
                }
               if (sub.ComplianceProcess__c == 'Conformité Pub') {
                    SBQQ__Subscription__c subPub = setConformitePub(sub);
                    if (subPub.MissingInformations__c == 'Conformité Pub') {
                        if (sub.SBQQ__RequiredById__c != null) {
                           setParentConforme(sub.SBQQ__RequiredById__c);
                       }
                    }
                }
            }
        } catch(Exception e) {
            Logs.error('SubscriptionComplianceCheck','Batch Compliance Check', e);
        }
    }
    
    global void finish(Database.BatchableContext cnx) {
    }
    

    private SBQQ__Subscription__c setConformiteImmoNeuf(SBQQ__Subscription__c sub) {
        if(sub.PromoterDescription__c != null && sub.FlowType__c != null && sub.ProductWorkflow__c != null
          && sub.ContractEmail__c != null && sub.CompanySiret__c != null && sub.CompanyName__c != null
          && sub.CompanyAddressStreet__c != null && sub.CompanyAddressZipcode__c != null && sub.CompanyAddressCity__c != null
          && sub.CompanyPhone__c != null && sub.ContactGender__c != null && sub.ContactFirstName__c != null 
          && sub.ContactLastName__c != null && sub.LeadPhone__c != null 
          )  {
            sub.Souscription_Conforme__c = true;
        }
        else{
        sub.MissingInformations__c = 'Conformité Immo neuf';
        }
        update sub;
        return sub;
    }

    private SBQQ__Subscription__c setConformitePub(SBQQ__Subscription__c sub) {

        if(sub.EffectiveEndDate__c > date.today().format())  {
            sub.Souscription_Conforme__c = true;
        }
        else{
        sub.MissingInformations__c = 'Conformité Pub';
        }
        update sub;
        return sub;
    }
    
    private void setParentConforme(String parentId) {
        SBQQ__Subscription__c[] parentSub = [SELECT Id, Souscription_Conforme__c FROM SBQQ__Subscription__c WHERE Status__c = :ELEMENTS_MANQUANTS 
                                           AND Souscription_Conforme__c = false AND Id = :parentId];
        if (parentSub.size() > 0) {
            parentSub[0].Souscription_Conforme__c = true;
            UPDATE parentSub[0];
        }
    }
}
