/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Queueable class to perform asynchronous processing of Stripe Checkout Session creation
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-05
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-05 v1.0.0 Initial creation
 *  - 2025-06-14 v1.0.1 Added logic to prevent recursion by bypassing triggers
 * -----------------------------------------------------------------------------
 */
public with sharing class StripeCustomerTriggerHandler {
  /*
  description: afterInsert method to handle the creation of Stripe customers by calling the Stripe API via a Queueable class.
  @param newList: List<Stripe_Customer__c> - The list of newly inserted Stripe_Customer__c records.
  */
  public static void afterInsert(List<Stripe_Customer__c> newList) {
    List<Stripe_Customer__c> customersToUpdate = new List<Stripe_Customer__c>();

    for (Stripe_Customer__c customer : newList) {
      if (TriggerBypass.bypassStripeCustomer == false) {
        try {
          // Create a Stripe customer using the Stripe API client
          StripeCustomerWrapper.CustomerRequest customerRequest = new StripeCustomerWrapper.CustomerRequest();
          customerRequest.name = customer.Name;
          customerRequest.email = customer.Email__c;
          customerRequest.phone = customer.Phone__c;

          // Call the Stripe API to create the customer
          System.enqueueJob(new CreateStripeCustomerQueuable(customer.Id));
        } catch (Exception e) {
          Logger.error('Error creating Stripe customer: ' + e.getMessage());
          Logger.saveLog();
        }
      }
    }
    update customersToUpdate;
  }
}
