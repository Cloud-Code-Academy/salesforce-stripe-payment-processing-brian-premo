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
  }

  public static void afterUpdate(
    List<Stripe_Customer__c> newList,
    Map<Id, Stripe_Customer__c> oldMap
  ) {
    for (Stripe_Customer__c customer : newList) {
      if (
        TriggerBypass.bypassStripeCustomer == false &&
        customer.Stripe_Customer_ID__c != null &&
        customer.Phone__c != oldMap.get(customer.Id).Phone__c &&
        customer.Email__c != oldMap.get(customer.Id).Email__c &&
        customer.Name__c != oldMap.get(customer.Id).Name__c &&
        customer.Default_Payment_Method__c !=
        oldMap.get(customer.Id).Default_Payment_Method__c
      ) {
        try {
          // Create a Stripe customer using the Stripe API client
          System.enqueueJob(new UpdateStripeCustomerQueuable(customer.Id));
        } catch (Exception e) {
          Logger.error('Error updating Stripe customer: ' + e.getMessage());
          Logger.saveLog();
        }
      }
    }
  }
}
