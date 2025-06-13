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

    // Prepare Subscription Request
    SubscriptionsWrapper sw = new SubscriptionsWrapper();
    sw.customer = stripeCustomerId;

    SubscriptionsWrapper.ItemWrapper iw = new SubscriptionsWrapper.ItemWrapper();
    iw.data = new List<SubscriptionsWrapper.Item>();

    SubscriptionsWrapper.Item item = new SubscriptionsWrapper.Item();
    item.price = new SubscriptionsWrapper.Price();
    item.price.id = priceId; // Set the price ID created above

    iw.data.add(item);
    sw.items = iw;

    //Call Stripe to Create Subscription
    try {
      SubscriptionsWrapper stripeSubscription = StripeAPIClient.createSubscription(
        sw
      );
      Logger.debug('Stripe Subscription created: ' + stripeSubscription);
      Logger.saveLog();
      if (stripeSubscription != null) {
        subscription.Subscription_Id__c = stripeSubscription.id;
        subscription.Current_Period_Start__c = SubscriptionsWrapper.convertUnixToDatetime(
          stripeSubscription.items.data[0].current_period_start
        );
        subscription.Current_Period_End__c = SubscriptionsWrapper.convertUnixToDatetime(
          stripeSubscription.items.data[0].current_period_end
        );
        subscription.Status__c = stripeSubscription.status;
        subscription.Price_ID__c = stripeSubscription.items.data[0].price.id;

        TriggerBypass.bypassStripeSubscription = true; // Bypass trigger to avoid recursion
        update subscription;
        TriggerBypass.bypassStripeSubscription = false; // Reset bypass after update
      }
    } catch (Exception e) {
      Logger.error('Error creating Stripe Subscription: ' + e.getMessage());
      Logger.saveLog();
      throw new CalloutException(
        'Error creating Stripe Subscription: ' + e.getMessage()
      );
    }
  }
}
