/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Queueable class to perform asynchronous processing of Subscriptions
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-05
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-05 v1.0.0 Initial creation
 *  - 2025-06-12 v1.0.1 Added logic to prevent recursion by bypassing triggers
 *  - 2026-06-20 v1.1.0 Refactor so that the queueable creates a Stripe Product and Price Object instead of *  Subscription
 * -----------------------------------------------------------------------------
 */
public with sharing class CreateStripeSubscriptionQueuable implements Queueable, Database.AllowsCallouts {
  private Id stripeSubscriptionId;

  public CreateStripeSubscriptionQueuable(Id stripeSubscriptionId) {
    this.stripeSubscriptionId = stripeSubscriptionId;
  }

  public void execute(QueueableContext context) {
    // Retrieve the Stripe_Subscription__c record
    Stripe_Subscription__c subscription = [
      SELECT
        Id,
        Status__c,
        Stripe_Customer__c,
        Stripe_Customer__r.Stripe_Customer_ID__c,
        Amount__c,
        Currency__c,
        Interval__c,
        Product_Name__c,
        Subscription_Id__c,
        Current_Period_Start__c,
        Current_Period_End__c
      FROM Stripe_Subscription__c
      WHERE Id = :stripeSubscriptionId
      LIMIT 1
    ];

    String stripeCustomerId = subscription.Stripe_Customer__r.Stripe_Customer_ID__c;
    //Stripe API requires sending amount in cents and as an Integer, so we muliply by 100 and convert to Integer
    Decimal amountDecimal = subscription.Amount__c * 100;
    Integer amount = (Integer) amountDecimal;
    String currencyCode = subscription.Currency__c;
    String interval = subscription.Interval__c;
    String productName = subscription.Product_Name__c;

    //Create Product in Stripe
    String productId = StripeAPIClient.createProduct(productName);

    //Create Price Object in Stripe
    String priceId = StripeAPIClient.createPrice(
      productId,
      amount,
      currencyCode,
      interval
    );

    // Update the subscription record with the created Price ID
    subscription.Price_ID__c = priceId;
    subscription.Status__c = 'Incomplete';
    subscription.Product_Id__c = productId;
    System.debug('Stripe Subscription created with Price ID: ' + priceId);
    try {
      update subscription;
    } catch (Exception e) {
      Logger.error(
        'Error updating Stripe Subscription: ' + e.getMessage(),
        stripeSubscriptionId
      );
      Logger.saveLog();
      throw new CalloutException(
        'Error updating Stripe Subscription: ' + e.getMessage()
      );
    }
  }
}
