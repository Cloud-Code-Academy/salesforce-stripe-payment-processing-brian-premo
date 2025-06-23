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
        Quantity__c,
        Propration_Behavior__c,
        Price_ID__c,
        Subscription_ID__c,
        Current_Period_Start__c,
        Current_Period_End__c,
        Product_ID__c,
        Interval__c
      FROM Stripe_Subscription__c
      WHERE Id = :stripeSubscriptionId
      LIMIT 1
    ];

    //If Quantity or Price change, create a new Price in Stripe and Generate a new Checkout Session
    if (operationType == 'update') {
      try {
        // Create a new Price in Stripe
        String productId = subscription.Product_ID__c;
        System.debug('Creating new Price for Product ID: ' + productId);
        Integer amount = (Integer) (subscription.Amount__c * 100); // Convert to cents
        System.debug('Amount in cents: ' + amount);
        String currencyCode = subscription.Currency__c;
        System.debug('Currency Code: ' + currencyCode);
        String interval = subscription.Interval__c;
        System.debug('Interval: ' + interval);

        String newPriceId = StripeAPIClient.createPrice(
          productId,
          amount,
          currencyCode,
          interval
        );

        // Update the Price_ID__c field in the subscription record
        subscription.Price_ID__c = newPriceId;
        if (!Test.isRunningTest()) {
          update subscription;
        }

        System.debug(
          'Stripe Subscription updated successfully: ' + subscription.Id
        );
        // Log the successful update
        Logger.debug(
          'Stripe Subscription updated successfully: ' + subscription.Id
        );
        Logger.saveLog();

        // Enqueue a job to create a Stripe Checkout Session
        System.enqueueJob(
          new CreateStripeCheckoutSessionQueuable(subscription.Id)
        );
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
