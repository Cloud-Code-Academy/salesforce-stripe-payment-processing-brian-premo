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
 *  - 2025-06-12 v1.0.1 Added methods for creating subscription wrappers and customer requests
 * -----------------------------------------------------------------------------
 */
@isTest
public with sharing class StripeTestDataFactory {
  public static Stripe_Customer__c createStripeCustomer() {
    Stripe_Customer__c customer = new Stripe_Customer__c();
    customer.Name__c = 'Test Customer';
    customer.Email__c = 'test@example.com';
    customer.Phone__c = '123-456-7890';
    return customer;
  }

  public static Stripe_Subscription__c createStripeSubscription() {
    Stripe_Subscription__c subscription = new Stripe_Subscription__c();
    subscription.Product_Name__c = 'Test Product';
    subscription.Currency__c = 'usd';
    subscription.Amount__c = 1000;
    subscription.Interval__c = 'month';
    subscription.Quantity__c = 1;
    return subscription;
  }

  public static Stripe_Subscription__c createStripeSubscriptionFailure() {
    Stripe_Subscription__c subscription = new Stripe_Subscription__c();
    //Do not set Amount to simulate failure
    subscription.Product_Name__c = 'Test Product';
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

  public static CheckoutSessionWrapper createCheckoutSessionWrapper(
    String customerId,
    String priceId,
    String currencyCode
  ) {
    CheckoutSessionWrapper sessionRequest = new CheckoutSessionWrapper();
    sessionRequest.customer = customerId;
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
    sessionRequest.currency_code = currencyCode;

    CheckoutSessionWrapper.LineItem lineItem = new CheckoutSessionWrapper.LineItem();
    lineItem.price = priceId;
    lineItem.quantity = 1;
    sessionRequest.line_items.add(lineItem);

    return sessionRequest;
  }

  public static String webhookCustomerUpdatedBody() {
    String body = '{"id":"evt_1RcsyrPuoWtmWWxEfvywRV38","object":"event","api_version":"2025-05-28.basil","created":1750618265,"data":{"object":{"id":"cus_123456","object":"customer","address":null,"balance":0,"created":1750618261,"currency":"usd","default_source":null,"delinquent":false,"description":"(created by Stripe CLI)","discount":null,"email":"testemail@test.com","invoice_prefix":"GLA5RA6I","invoice_settings":{"custom_fields":null,"default_payment_method":"pm_123456","footer":null,"rendering_options":null},"livemode":false,"metadata":{},"name":"Test Customer Name","next_invoice_sequence":2,"phone":"1231231234","preferred_locales":[],"shipping":null,"tax_exempt":"none","test_clock":null},"previous_attributes":{"next_invoice_sequence":1}},"livemode":false,"pending_webhooks":1,"request":{"id":"req_6OOL3P0bNLI5B7","idempotency_key":"c710aeeb-a254-4ab7-bf4e-5d8140389dae"},"type":"customer.updated"}';
    return body;
  }

  public static String webhookSubscriptionUpdatedWrapper() {
    StripeSubscriptionEventWrapper subscriptionEvent = new StripeSubscriptionEventWrapper();
    subscriptionEvent.id = 'sub_123456';
    subscriptionEvent.data = new StripeSubscriptionEventWrapper.DataWrapper();
    subscriptionEvent.data.object_wrapper = new StripeSubscriptionEventWrapper.ObjectWrapper();
    subscriptionEvent.data.object_wrapper.id = 'sub_123456';
    subscriptionEvent.data.object_wrapper.status = 'active';
    subscriptionEvent.data.object_wrapper.default_payment_method = 'pm_123456';
    subscriptionEvent.data.object_wrapper.items = new StripeSubscriptionEventWrapper.ItemsWrapper();
    subscriptionEvent.data.object_wrapper.items.data = new List<StripeSubscriptionEventWrapper.SubscriptionItem>();
    StripeSubscriptionEventWrapper.SubscriptionItem item = new StripeSubscriptionEventWrapper.SubscriptionItem();
    item.quantity = 1;
    item.current_period_start = System.now().getTime() / 1000;
    item.current_period_end = System.now().getTime() / 1000 + 2592000; // 30 days later
    item.price = new StripeSubscriptionEventWrapper.PriceWrapper();
    item.price.id = 'price_123456';
    item.price.object_type = 'price';
    item.price.unit_amount = 1000; // $10.00
    subscriptionEvent.data.object_wrapper.items.data.add(item);
    subscriptionEvent.type = 'customer.subscription.updated';
    String payload = JSON.serialize(subscriptionEvent);
    return payload;
  }

  public static String webhookSubscriptionCreatedWrapper() {
    StripeSubscriptionEventWrapper subscriptionEvent = new StripeSubscriptionEventWrapper();
    subscriptionEvent.id = 'sub_123456';
    subscriptionEvent.data = new StripeSubscriptionEventWrapper.DataWrapper();
    subscriptionEvent.data.object_wrapper = new StripeSubscriptionEventWrapper.ObjectWrapper();
    subscriptionEvent.data.object_wrapper.id = 'sub_123456';
    subscriptionEvent.data.object_wrapper.status = 'active';
    subscriptionEvent.data.object_wrapper.default_payment_method = 'pm_123456';
    subscriptionEvent.data.object_wrapper.items = new StripeSubscriptionEventWrapper.ItemsWrapper();
    subscriptionEvent.data.object_wrapper.items.data = new List<StripeSubscriptionEventWrapper.SubscriptionItem>();
    StripeSubscriptionEventWrapper.SubscriptionItem item = new StripeSubscriptionEventWrapper.SubscriptionItem();
    item.quantity = 1;
    item.current_period_start = System.now().getTime() / 1000;
    item.current_period_end = System.now().getTime() / 1000 + 2592000; // 30 days later
    item.price = new StripeSubscriptionEventWrapper.PriceWrapper();
    item.price.id = 'price_123456';
    item.price.object_type = 'price';
    item.price.unit_amount = 1000; // $10.00
    subscriptionEvent.data.object_wrapper.items.data.add(item);
    subscriptionEvent.type = 'customer.subscription.created';
    String payload = JSON.serialize(subscriptionEvent);
    return payload;
  }

  public static String webhookSubscriptionDeletedWrapper() {
    StripeSubscriptionEventWrapper subscriptionEvent = new StripeSubscriptionEventWrapper();
    subscriptionEvent.id = 'sub_123456';
    subscriptionEvent.data = new StripeSubscriptionEventWrapper.DataWrapper();
    subscriptionEvent.data.object_wrapper = new StripeSubscriptionEventWrapper.ObjectWrapper();
    subscriptionEvent.data.object_wrapper.id = 'sub_123456';
    subscriptionEvent.data.object_wrapper.status = 'canceled';
    subscriptionEvent.data.object_wrapper.items = new StripeSubscriptionEventWrapper.ItemsWrapper();
    subscriptionEvent.data.object_wrapper.items.data = new List<StripeSubscriptionEventWrapper.SubscriptionItem>();
    StripeSubscriptionEventWrapper.SubscriptionItem item = new StripeSubscriptionEventWrapper.SubscriptionItem();
    item.quantity = 1;
    item.current_period_start = System.now().getTime() / 1000;
    item.current_period_end = System.now().getTime() / 1000 + 2592000; // 30 days later
    item.price = new StripeSubscriptionEventWrapper.PriceWrapper();
    subscriptionEvent.data.object_wrapper.items.data.add(item);
    subscriptionEvent.type = 'customer.subscription.deleted';
    String payload = JSON.serialize(subscriptionEvent);
    return payload;
  }

  public static String webhookInvoicePaymentSucceededWrapper() {
    StripeInvoiceWrapper invoiceWrapper = new StripeInvoiceWrapper();
    invoiceWrapper.id = 'in_12345';
    invoiceWrapper.type = 'invoice.payment_succeeded';
    invoiceWrapper.data = new StripeInvoiceWrapper.DataWrapper();
    invoiceWrapper.data.object_wrapper = new StripeInvoiceWrapper.ObjectWrapper();
    invoiceWrapper.data.object_wrapper.id = 'in_12345';
    invoiceWrapper.data.object_wrapper.customer = 'cus_12345';
    invoiceWrapper.data.object_wrapper.invoice_pdf = 'https://example.com/invoice.pdf';
    invoiceWrapper.data.object_wrapper.created = '1750711342';
    invoiceWrapper.data.object_wrapper.currency_code = 'usd';
    invoiceWrapper.data.object_wrapper.amount_paid = 1000;
    invoiceWrapper.data.object_wrapper.status = 'paid';
    invoiceWrapper.data.object_wrapper.lines = new StripeInvoiceWrapper.LineItem();
    invoiceWrapper.data.object_wrapper.lines.data = new List<StripeInvoiceWrapper.LineItemData>();
    StripeInvoiceWrapper.LineItemData lineItem = new StripeInvoiceWrapper.LineItemData();
    lineItem.amount = 1000;
    lineItem.parent = new StripeInvoiceWrapper.ParentWrapper();
    lineItem.parent.subscription_item_details = new StripeInvoiceWrapper.SubscriptionItemDetailsWrapper();
    lineItem.parent.subscription_item_details.subscription = 'sub_12345';
    invoiceWrapper.data.object_wrapper.lines.data.add(lineItem);
    String payload = JSON.serialize(invoiceWrapper);
    return payload;
  }

  public static String webhookInvoicePaymentFailureWrapper() {
    StripeInvoiceWrapper invoiceWrapper = new StripeInvoiceWrapper();
    invoiceWrapper.id = 'in_12345';
    invoiceWrapper.data = new StripeInvoiceWrapper.DataWrapper();
    invoiceWrapper.type = 'invoice.payment_failed';
    invoiceWrapper.data.object_wrapper = new StripeInvoiceWrapper.ObjectWrapper();
    invoiceWrapper.data.object_wrapper.id = 'in_12345';
    invoiceWrapper.data.object_wrapper.customer = 'cus_12345';
    invoiceWrapper.data.object_wrapper.invoice_pdf = 'https://example.com/invoice.pdf';
    invoiceWrapper.data.object_wrapper.created = '1750711342';
    invoiceWrapper.data.object_wrapper.currency_code = 'usd';
    invoiceWrapper.data.object_wrapper.amount_paid = 1000;
    invoiceWrapper.data.object_wrapper.status = 'failed';
    invoiceWrapper.data.object_wrapper.lines = new StripeInvoiceWrapper.LineItem();
    invoiceWrapper.data.object_wrapper.lines.data = new List<StripeInvoiceWrapper.LineItemData>();
    StripeInvoiceWrapper.LineItemData lineItem = new StripeInvoiceWrapper.LineItemData();
    lineItem.amount = 0;
    lineItem.parent = new StripeInvoiceWrapper.ParentWrapper();
    lineItem.parent.subscription_item_details = new StripeInvoiceWrapper.SubscriptionItemDetailsWrapper();
    lineItem.parent.subscription_item_details.subscription = 'sub_12345';
    invoiceWrapper.data.object_wrapper.lines.data.add(lineItem);
    String payload = JSON.serialize(invoiceWrapper);
    return payload;
  }
}
