/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Trigger Handler for Stripe Subscription operations
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-12
 * LAST EDITED :
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-07 v1.0.0 Initial creation
 * -----------------------------------------------------------------------------
 */
public with sharing class StripeSubscriptionTriggerHandler {
  public static void afterInsert(List<Stripe_Subscription__c> newList) {
    List<Stripe_Subscription__c> subscriptionsToUpdate = new List<Stripe_Subscription__c>();

    for (Stripe_Subscription__c subscription : newList) {
      if (TriggerBypass.bypassStripeSubscription == false) {
        try {
          // Call the Stripe API to create the customer
          System.enqueueJob(
            new CreateStripeSubscriptionQueuable(subscription.Id)
          );
        } catch (Exception e) {
          System.debug('Error creating Stripe customer: ' + e.getMessage());
        }
      }
      update subscriptionsToUpdate;
    }
  }

  /*
  description: afterUpdate method to handle updates to Stripe customers.
  @param newList: List<Stripe_Customer__c> - The list of updated Stripe_Customer__c records.
  @param oldMap: Map<Id, Stripe_Customer__c> - The map of old Stripe_Customer__c records before the update.
  */
  public static void afterUpdate(
    List<Stripe_Subscription__c> newList,
    Map<Id, Stripe_Subscription__c> oldMap
  ) {
    for (Stripe_Subscription__c subscription : newList) {
      Stripe_Subscription__c oldSubscription = oldMap.get(subscription.Id);

      //Handle Price ID changes
      if (
        oldSubscription != null &&
        oldSubscription.Price_ID__c != subscription.Price_ID__c &&
        TriggerBypass.bypassStripeSubscription == false
      ) {
        System.enqueueJob(
          new UpdateStripeSubscriptionQueuable(subscription.Id, 'update')
        );
      }

      //Handle Subscription Cancellation
      if (
        oldSubscription != null &&
        oldSubscription.Status__c != subscription.Status__c &&
        subscription.Status__c == 'canceled'
      ) {
        System.enqueueJob(
          new UpdateStripeSubscriptionQueuable(subscription.Id, 'cancel')
        );
      }
    }
  }
}
