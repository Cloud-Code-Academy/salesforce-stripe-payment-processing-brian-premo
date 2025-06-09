/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Queueable class to perform asynchronous processing of Updating Customers
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-05
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-07 v1.0.0 Initial creation
 * -----------------------------------------------------------------------------
 */
public with sharing class UpdateStripeSubscriptionQueuable implements Queueable, Database.AllowsCallouts {
  private Id stripeSubscriptionId;
  private String operationType;

  public UpdateStripeSubscriptionQueuable(
    Id stripeSubscriptionId,
    String operationType
  ) {
    this.stripeSubscriptionId = stripeSubscriptionId;
    this.operationType = operationType;
  }

  public void execute(QueueableContext context) {
    // Retrieve the Stripe_Subscription__c record
    Stripe_Subscription__c subscription = [
      SELECT
        Id,
        Status__c,
        Amount__c,
        Currency__c,
        Propration_Behavior__c,
        Price_ID__c,
        Subscription_ID__c,
        Current_Period_Start__c,
        Current_Period_End__c
      FROM Stripe_Subscription__c
      WHERE Id = :stripeSubscriptionId
      LIMIT 1
    ];

    //Handle Price ID changes
    if (operationType == 'update') {
      //Prepare Subscription Request
      SubscriptionsWrapper sw = new SubscriptionsWrapper();
      sw.id = subscription.Subscription_ID__c;
      sw.prorationBehavior = subscription.Propration_Behavior__c;

      SubscriptionsWrapper.ItemWrapper iw = new SubscriptionsWrapper.ItemWrapper();
      iw.data = new List<SubscriptionsWrapper.Item>();

      SubscriptionsWrapper.Item item = new SubscriptionsWrapper.Item();
      item.price = new SubscriptionsWrapper.Price();
      item.price.id = subscription.Price_ID__c;

      iw.data.add(item);
      sw.items = iw;

      try {
        SubscriptionsWrapper stripeSubscription = StripeAPIClient.updateSubscription(
          sw
        );
        // Update the Stripe_Subscription__c record with the new Status
        subscription.Status__c = stripeSubscription.status;
      } catch (Exception e) {
        Logger.error(
          'Error updating Stripe subscription: ' + e.getMessage(),
          subscription
        );
        Logger.saveLog();
      }
    }
    //Handle Subscription Cancellation
    else if (operationType == 'cancel') {
      try {
        // Call Stripe API to cancel the subscription
        StripeAPIClient.cancelSubscription(subscription.Subscription_ID__c);
        // Update the Stripe_Subscription__c record with the new Status
        subscription.Status__c = 'canceled';
      } catch (Exception e) {
        Logger.error(
          'Error canceling Stripe subscription: ' + e.getMessage(),
          subscription
        );
        Logger.saveLog();
      }
    }
  }
}
