/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Queueable class to perform asynchronous processing of Stripe Checkout Session creation
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-14
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-05 v1.0.0 Initial creation
 * -----------------------------------------------------------------------------
 */
public with sharing class CreateStripeCheckoutSessionQueuable implements Queueable, Database.AllowsCallouts {
  // Add any parameters you need to pass to the queueable
  private Id stripeSubscriptionId;

  public CreateStripeCheckoutSessionQueuable(Id stripeSubscriptionId) {
    this.stripeSubscriptionId = stripeSubscriptionid;
  }

  public void execute(QueueableContext context) {
    Stripe_Subscription__c subscription = [
      SELECT
        Id,
        Stripe_Customer__c,
        Stripe_Customer__r.Stripe_Customer_ID__c,
        Currency__c,
        Quantity__c,
        Price_ID__c
      FROM Stripe_Subscription__c
      WHERE Id = :stripeSubscriptionId
      LIMIT 1
    ];

    //Prepare the request for Stripe Checkout Session
    CheckoutSessionWrapper sessionRequest = new CheckoutSessionWrapper();
    sessionRequest.customer = subscription.Stripe_Customer__r.Stripe_Customer_ID__c;
    sessionRequest.mode = 'subscription';
    sessionRequest.success_url = Redirect_URL__mdt.getInstance(
        'Payment_Successful'
      )
      .Redirect_URL__c;
    sessionRequest.cancel_url = Redirect_URL__mdt.getInstance(
        'Payment_Cancelled'
      )
      .Redirect_URL__c;

    sessionRequest.line_items = new List<CheckoutSessionWrapper.LineItem>();
    sessionRequest.currency_code = subscription.Currency__c;

    CheckoutSessionWrapper.LineItem lineItem = new CheckoutSessionWrapper.LineItem();
    lineItem.price = subscription.Price_ID__c; // Assuming this is the price ID

    if (subscription.Quantity__c == null) {
      lineItem.quantity = 1; // Default to 1 if quantity is not set
    } else {
      lineItem.quantity = (Integer) subscription.Quantity__c;
    }
    sessionRequest.line_items.add(lineItem);

    System.debug(
      'Creating Checkout Session for Subscription: ' + subscription.Id
    );
    System.debug('Session Request: ' + sessionRequest);

    //Call the Stripe API to create a checkout session
    CheckoutSessionWrapper checkoutSession = StripeAPIClient.createCheckoutSession(
      sessionRequest
    );

    Logger.debug('Checkout Session Response: ' + checkoutSession);
    Logger.saveLog();

    // Handle the response from Stripe
    if (checkoutSession != null && checkoutSession.id != null) {
      // Update the Stripe_Subscription__c record with the session ID
      subscription.Stripe_Checkout__c = checkoutSession.id;
      subscription.Sync_Status__c = 'Checkout Created';
      subscription.Checkout_URL__c = checkoutSession.url;

      try {
        update subscription;
      } catch (DMLException e) {
        Logger.error('Error updating subscription: ' + e.getMessage());
        Logger.saveLog();
      }
    }
  }
}
