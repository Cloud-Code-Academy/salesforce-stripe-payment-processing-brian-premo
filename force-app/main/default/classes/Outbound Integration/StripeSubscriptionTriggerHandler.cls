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
 *  - 2025-06-12 v1.0.1 Added support for creating checkout sessions
 * -----------------------------------------------------------------------------
 */
public with sharing class StripeSubscriptionTriggerHandler {
  public static void afterInsert(List<Stripe_Subscription__c> newList) {
    List<Stripe_Subscription__c> subscriptionsToUpdate = new List<Stripe_Subscription__c>();

    for (Stripe_Subscription__c subscription : newList) {
      if (TriggerBypass.bypassStripeSubscription == false) {
        // Call the Stripe API to create the price and product
        System.enqueueJob(
          new CreateStripeSubscriptionQueuable(subscription.Id)
        );
      }
    }
    update subscriptionsToUpdate;
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

      //Handle Price Change
      if (
        oldSubscription != null &&
        oldSubscription.Price_ID__c == subscription.Price_ID__c &&
        oldSubscription.Amount__c != subscription.Amount__c
      ) {
        System.enqueueJob(
          new UpdateStripeSubscriptionQueuable(subscription.Id, 'update')
        );
      }
      //Handle Subscription Cancellation
      else if (
        oldSubscription != null &&
        oldSubscription.Status__c != subscription.Status__c &&
        subscription.Status__c == 'canceled'
      ) {
        System.enqueueJob(
          new UpdateStripeSubscriptionQueuable(subscription.Id, 'cancel')
        );
      }
      //Handle Subscription Price Update for First Time
      else if (
        oldSubscription.Price_ID__c == null &&
        oldSubscription.Price_ID__c != subscription.Price_ID__c
      ) {
        System.enqueueJob(
          new CreateStripeCheckoutSessionQueuable(subscription.Id)
        );
      }
    }
  }
}
