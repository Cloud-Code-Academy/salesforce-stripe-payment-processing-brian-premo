/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Queueable class to perform asynchronous processing of Customer creation
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-05
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-05 v1.0.0 Initial creation
 * -----------------------------------------------------------------------------
 */
public with sharing class CreateStripeCustomerQueuable implements Queueable, Database.AllowsCallouts {
  private Id stripeCustomerId;

  public CreateStripeCustomerQueuable(Id stripeCustomerId) {
    this.stripeCustomerId = stripeCustomerId;
  }

  public void execute(QueueableContext context) {
    // Retrieve the Stripe_Customer__c record
    Stripe_Customer__c customer = [
      SELECT Id, Name, Email__c, Phone__c
      FROM Stripe_Customer__c
      WHERE Id = :stripeCustomerId
      LIMIT 1
    ];

    try {
      // Create a Stripe customer using the Stripe API client
      StripeCustomerWrapper.CustomerRequest customerRequest = new StripeCustomerWrapper.CustomerRequest();
      customerRequest.name = customer.Name;
      customerRequest.email = customer.Email__c;
      customerRequest.phone = customer.Phone__c;

      // Call the Stripe API to create the customer
      StripeCustomerWrapper response = StripeAPIClient.createCustomer(
        customerRequest
      );

      // Update the Stripe_Customer__c record with the returned ID
      customer.Stripe_Customer_ID__c = response.id;
      update customer;
    } catch (Exception e) {
      Logger.error('Error creating Stripe customer: ' + e.getMessage());
      Logger.saveLog();
    }
  }
}
