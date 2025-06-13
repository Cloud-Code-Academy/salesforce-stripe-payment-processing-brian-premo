/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Factory class to create test data for Stripe-related objects
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-12
 * LAST EDITED :
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-12 v1.0.0 Initial creation
 * -----------------------------------------------------------------------------
 */
@isTest
public with sharing class StripeTestDataFactory {
  public static Stripe_Customer__c createStripeCustomer() {
    Stripe_Customer__c customer = new Stripe_Customer__c();
    customer.Name = 'Test Customer';
    customer.Email__c = 'test@example.com';
    customer.Phone__c = '123-456-7890';
    return customer;
  }

  public static Stripe_Subscription__c createStripeSubscription() {
    Stripe_Subscription__c subscription = new Stripe_Subscription__c();
    subscription.Name = 'Test Subscription';
    subscription.Product_Name__c = 'Test Product';
    subscription.Currency__c = 'usd';
    subscription.Amount__c = 1000;
    subscription.Interval__c = 'month';
    subscription.Price_ID__c = 'price_123456';
    return subscription;
  }

  public static Stripe_Subscription__c createStripeSubscriptionFailure() {
    Stripe_Subscription__c subscription = new Stripe_Subscription__c();
    //Set invalid currency to simulate failure
    subscription.Name = 'Test Subscription';
    subscription.Product_Name__c = 'Test Product';
    subscription.Currency__c = 'notarealcurrency';
    subscription.Amount__c = 1000;
    subscription.Interval__c = 'month';
    return subscription;
  }

  public static Stripe_Subscription__c updateStripeSubscriptionSuccess(
    Stripe_Subscription__c subscription
  ) {
    subscription.Price_ID__c = 'price_123456';
    subscription.Propration_Behavior__c = 'always_invoice';
    return subscription;
  }

  public static Stripe_Subscription__c updateStripeSubscriptionFailure(
    Stripe_Subscription__c subscription
  ) {
    //Set invalid proration behavior to simulate failure
    subscription.Price_ID__c = 'price_123456';
    subscription.Propration_Behavior__c = 'notarealbehavior';
    return subscription;
  }

  public static Stripe_Subscription__c cancelStripeSubscription(
    Stripe_Subscription__c subscription
  ) {
    subscription.Subscription_ID__c = 'sub_123456';
    subscription.Status__c = 'canceled';
    return subscription;
  }

  public static SubscriptionsWrapper createSubscriptionWrapper(
    String customerId,
    String priceId
  ) {
    SubscriptionsWrapper subscriptionWrapper = new SubscriptionsWrapper();
    subscriptionWrapper.customer = customerId;

    SubscriptionsWrapper.ItemWrapper itemWrapper = new SubscriptionsWrapper.ItemWrapper();
    itemWrapper.data = new List<SubscriptionsWrapper.Item>();

    SubscriptionsWrapper.Item item = new SubscriptionsWrapper.Item();
    item.price = new SubscriptionsWrapper.Price();
    item.price.id = priceId;

    itemWrapper.data.add(item);
    subscriptionWrapper.items = itemWrapper;

    return subscriptionWrapper;
  }

  public static SubscriptionsWrapper updateSubscriptionWrapper(
    String customerId,
    String priceId
  ) {
    SubscriptionsWrapper wrapper = new SubscriptionsWrapper();
    wrapper.id = customerId;
    wrapper.customer = 'cus_12345';
    wrapper.prorationBehavior = 'create_prorations'; // Ensure this is set

    SubscriptionsWrapper.ItemWrapper itemWrapper = new SubscriptionsWrapper.ItemWrapper();
    itemWrapper.data = new List<SubscriptionsWrapper.Item>();

    SubscriptionsWrapper.Item item = new SubscriptionsWrapper.Item();
    item.price = new SubscriptionsWrapper.Price();
    item.price.id = priceId; // Ensure this is set

    itemWrapper.data.add(item);
    wrapper.items = itemWrapper;

    return wrapper;
  }

  public static StripeCustomerWrapper.CustomerRequest createStripeCustomerWrapper(
    String name,
    String email,
    String phone
  ) {
    StripeCustomerWrapper.CustomerRequest customerRequest = new StripeCustomerWrapper.CustomerRequest();
    customerRequest.email = email;
    customerRequest.phone = phone;
    customerRequest.name = name;
    return customerRequest;
  }
}
