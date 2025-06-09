public with sharing class StripeCustomerTriggerHandler {
  /*
  description: afterInsert method to handle the creation of Stripe customers by calling the Stripe API via a Queueable class.
  @param newList: List<Stripe_Customer__c> - The list of newly inserted Stripe_Customer__c records.
  */
  public static void afterInsert(List<Stripe_Customer__c> newList) {
    List<Stripe_Customer__c> customersToUpdate = new List<Stripe_Customer__c>();

    for (Stripe_Customer__c customer : newList) {
      try {
        // Create a Stripe customer using the Stripe API client
        StripeCustomerWrapper.CustomerRequest customerRequest = new StripeCustomerWrapper.CustomerRequest();
        customerRequest.name = customer.Name;
        customerRequest.email = customer.Email__c;
        customerRequest.phone = customer.Phone__c;

        // Call the Stripe API to create the customer
        System.enqueueJob(new CreateStripeCustomerQueuable(customer.Id));
      } catch (Exception e) {
        System.debug('Error creating Stripe customer: ' + e.getMessage());
      }
    }
    update customersToUpdate;
  }
}
