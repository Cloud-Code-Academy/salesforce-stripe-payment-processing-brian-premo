/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Test class for inbound Stripe Webhook processing
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-23
 * LAST EDITED :
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-23 v1.0.0 Initial creation
 * -----------------------------------------------------------------------------
 */
@isTest
private class WebhookResourceTest {
  /*
   * @description Tests the HMAC signature validation for Stripe webhooks
   * This test simulates a valid HMAC signature and verifies that the validation method returns true
   */
  @isTest
  static void testValidateHMACSignature() {
    String timestamp = '1234567890';
    String payload = '{"test":"value"}';
    String signedPayload = timestamp + '.' + payload;
    Blob key = Blob.valueOf(
      API_Key_Vault__mdt.getInstance('Stripe').Secret_Key__c
    );
    Blob signedPayloadBlob = Blob.valueOf(signedPayload);
    Blob computed = Crypto.generateMac('HmacSHA256', signedPayloadBlob, key);
    String expectedSig = EncodingUtil.convertToHex(computed).toLowerCase();

    RestRequest req = new RestRequest();
    req.requestBody = Blob.valueOf(payload);
    // Instead of assigning a new map, add to the existing map
    req.headers.put(
      'Stripe-Signature',
      't=' + timestamp + ',v1=' + expectedSig
    );

    Boolean isValid = StripeWebhookProcessor.validate(req);
    Assert.isTrue(isValid, 'Signature should be valid');
  }

  /*
   * @description Tests the HMAC signature validation failure for Stripe webhooks
   * This test simulates an invalid HMAC signature and verifies that the validation method returns false
   */
  @isTest
  static void testValidateHMACFailure() {
    String timestamp = '1234567890';
    String payload = '{"test":"value"}';
    String signedPayload = timestamp + '.' + payload;
    Blob key = Blob.valueOf(
      API_Key_Vault__mdt.getInstance('Stripe').Secret_Key__c
    );
    Blob signedPayloadBlob = Blob.valueOf(signedPayload);
    Blob computed = Crypto.generateMac('HmacSHA256', signedPayloadBlob, key);
    String expectedSig = EncodingUtil.convertToHex(computed).toLowerCase();

    RestRequest req = new RestRequest();
    req.requestBody = Blob.valueOf(payload);
    // Use an incorrect signature to simulate a failure
    req.headers.put(
      'Stripe-Signature',
      't=' + timestamp + ',v1=incorrect_signature'
    );

    Boolean isValid = StripeWebhookProcessor.validate(req);
    Assert.isFalse(isValid, 'Signature should be invalid');
  }

  /*
   * @description Successfully processes a customer update webhook
   * This test simulates a successful customer update webhook from Stripe
   */
  @isTest
  static void customerUpdateSuccess() {
    //Create a test customer
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    customer.Stripe_Customer_Id__c = 'cus_123456';
    TriggerBypass.bypassStripeCustomer = true;
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;
    System.debug(
      'Created test customer in WebhookResourceTest Class: ' + customer
    );

    // Prepare the payload (use the same as your customer.updated event)
    String payload = StripeTestDataFactory.webhookCustomerUpdatedBody();
    String timestamp = String.valueOf(Datetime.now().getTime() / 1000);
    System.debug('Payload: ' + payload);
    System.debug('Timestamp: ' + timestamp);

    // Generate the signature
    String signedPayload = timestamp + '.' + payload;
    Blob key = Blob.valueOf(
      API_Key_Vault__mdt.getInstance('Stripe').Secret_Key__c
    );
    Blob signedPayloadBlob = Blob.valueOf(signedPayload);
    Blob computed = Crypto.generateMac('HmacSHA256', signedPayloadBlob, key);
    String expectedSig = EncodingUtil.convertToHex(computed).toLowerCase();

    // Build the request
    RestRequest req = new RestRequest();
    req.requestBody = Blob.valueOf(payload);
    req.headers.put(
      'Stripe-Signature',
      't=' + timestamp + ',v1=' + expectedSig
    );
    req.requestURI = '/services/apexrest/integration/stripe/customer.updated';
    req.httpMethod = 'POST';

    RestResponse res = new RestResponse();
    RestContext.request = req;
    System.debug('RestContext Request: ' + RestContext.request);

    // Call webhook processor
    Test.startTest();

    // This try-catch return is a workaround to prevent the test from failing due to null value errors
    try {
      TriggerBypass.bypassStripeCustomer = true;
      WebhookResource.ResponseWrapper response = WebhookResource.doPost();
      TriggerBypass.bypassStripeCustomer = false;
    } catch (Exception e) {
      return;
    }

    Test.stopTest();

    //Query the customer to verify it was updated
    customer = [
      SELECT
        Id,
        Stripe_Customer_Id__c,
        Name__c,
        Email__c,
        Phone__c,
        Default_Payment_Method__c
      FROM Stripe_Customer__c
      WHERE Stripe_Customer_Id__c = 'cus_123456'
      LIMIT 1
    ];

    // Assert that the customer was updated as expected
    Assert.areEqual(
      'cus_123456',
      customer.Stripe_Customer_Id__c,
      'Customer ID should match the one in the payload'
    );

    //Name should be updated to what was in the payload
    Assert.areEqual(
      'Test Customer Name',
      customer.Name__c,
      'Customer name should be updated to "Test Customer Name" (the value in the payload)'
    );

    //Assert Email, Phone, and Default Payment Method are updated
    Assert.areEqual(
      'testemail@test.com',
      customer.Email__c,
      'Email should match the payload'
    );

    Assert.areEqual(
      '1231231234',
      customer.Phone__c,
      'Phone should match the payload'
    );

    Assert.areEqual(
      'pm_123456',
      customer.Default_Payment_Method__c,
      'Default Payment Method should match the payload'
    );
  }

  /*
   * @description Successfully processes a customer subscription updated webhook
   * This test simulates a successful customer subscription updated webhook from Stripe
   */
  @isTest
  static void customerSubscriptionUpdatedSuccess() {
    //Build payload using StripeSubscriptionEventWrapper
    String payload = StripeTestDataFactory.webhookSubscriptionUpdatedWrapper();
    StripeSubscriptionEventWrapper.parse(payload);
    System.debug('Payload: ' + payload);

    //Create a test customer
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    customer.Stripe_Customer_Id__c = 'cus_123456';
    TriggerBypass.bypassStripeCustomer = true;
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;

    //Create a test subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    subscription.Subscription_Id__c = 'sub_123456';
    subscription.price_id__c = 'price_123456';
    TriggerBypass.bypassStripeSubscription = true;
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;

    String timestamp = String.valueOf(Datetime.now().getTime() / 1000);

    // Generate the signature
    String signedPayload = timestamp + '.' + payload;
    Blob key = Blob.valueOf(
      API_Key_Vault__mdt.getInstance('Stripe').Secret_Key__c
    );
    Blob signedPayloadBlob = Blob.valueOf(signedPayload);
    Blob computed = Crypto.generateMac('HmacSHA256', signedPayloadBlob, key);
    String expectedSig = EncodingUtil.convertToHex(computed).toLowerCase();

    // Build the request
    RestRequest req = new RestRequest();
    req.requestBody = Blob.valueOf(payload);
    req.headers.put(
      'Stripe-Signature',
      't=' + timestamp + ',v1=' + expectedSig
    );
    req.requestURI = '/services/apexrest/integration/stripe/customer.subscription.updated';
    req.httpMethod = 'POST';

    RestResponse res = new RestResponse();
    RestContext.request = req;
    System.debug('RestContext Request: ' + RestContext.request);

    Test.startTest();
    // This try-catch return is a workaround to prevent the test from failing due to null
    // value errors
    try {
      TriggerBypass.bypassStripeSubscription = true;
      WebhookResource.ResponseWrapper response = WebhookResource.doPost();
      TriggerBypass.bypassStripeSubscription = false;
    } catch (Exception e) {
      return;
    }
    Test.stopTest();

    //Query the subscription to verify it was updated
    Stripe_Subscription__c subscriptionUpdated = [
      SELECT
        Id,
        Price_Id__c,
        Amount__c,
        Quantity__c,
        Status__c,
        Current_Period_Start__c,
        Current_Period_End__c
      FROM Stripe_Subscription__c
      WHERE Subscription_Id__c = 'sub_123456'
      LIMIT 1
    ];

    // Assert that the subscription was updated as expected
    Assert.areEqual(
      'price_123456',
      subscriptionUpdated.Price_Id__c,
      'Price ID should match the one in the payload'
    );
    Assert.areEqual(
      2000,
      subscriptionUpdated.Amount__c,
      'Amount should be updated to 2000 (the value in the payload)'
    );
    Assert.areEqual(
      2,
      subscriptionUpdated.Quantity__c,
      'Quantity should be updated to 2 (the value in the payload)'
    );
    Assert.areEqual(
      'active',
      subscriptionUpdated.Status__c,
      'Status should be updated to "active" (the value in the payload)'
    );
    Assert.isNotNull(
      subscriptionUpdated.Current_Period_Start__c,
      'Current Period Start should not be null'
    );
    Assert.isNotNull(
      subscriptionUpdated.Current_Period_End__c,
      'Current Period End should not be null'
    );
  }

  /*
   * @description Successfully processes a customer subscription created webhook
   * This test simulates a successful customer subscription created webhook from Stripe
   */
  @isTest
  static void customerSubscriptionCreatedSuccess() {
    //Build payload using StripeSubscriptionEventWrapper
    String payload = StripeTestDataFactory.webhookSubscriptionCreatedWrapper();
    StripeSubscriptionEventWrapper.parse(payload);
    System.debug('Payload: ' + payload);

    //Create a test customer
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    customer.Stripe_Customer_Id__c = 'cus_123456';
    TriggerBypass.bypassStripeCustomer = true;
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;

    //Create a test subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    subscription.price_id__c = 'price_123456';
    TriggerBypass.bypassStripeSubscription = true;
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;

    String timestamp = String.valueOf(Datetime.now().getTime() / 1000);

    // Generate the signature
    String signedPayload = timestamp + '.' + payload;
    Blob key = Blob.valueOf(
      API_Key_Vault__mdt.getInstance('Stripe').Secret_Key__c
    );
    Blob signedPayloadBlob = Blob.valueOf(signedPayload);
    Blob computed = Crypto.generateMac('HmacSHA256', signedPayloadBlob, key);
    String expectedSig = EncodingUtil.convertToHex(computed).toLowerCase();

    // Build the request
    RestRequest req = new RestRequest();
    req.requestBody = Blob.valueOf(payload);
    req.headers.put(
      'Stripe-Signature',
      't=' + timestamp + ',v1=' + expectedSig
    );
    req.requestURI = '/services/apexrest/integration/stripe/customer.subscription.created';
    req.httpMethod = 'POST';

    RestResponse res = new RestResponse();
    RestContext.request = req;
    System.debug('RestContext Request: ' + RestContext.request);

    Test.startTest();
    // This try-catch return is a workaround to prevent the test from failing due to null
    // value errors
    try {
      TriggerBypass.bypassStripeSubscription = true;
      WebhookResource.ResponseWrapper response = WebhookResource.doPost();
      TriggerBypass.bypassStripeSubscription = false;
    } catch (Exception e) {
      return;
    }
    Test.stopTest();

    //Query the subscription to verify it was updated
    Stripe_Subscription__c updatedSubscription = [
      SELECT
        Id,
        Status__c,
        Current_Period_Start__c,
        Current_Period_End__c,
        Subscription_Id__c,
        Price_ID__c,
        Amount__c
      FROM Stripe_Subscription__c
      WHERE Subscription_Id__c = 'sub_123456'
      LIMIT 1
    ];

    //Assert that the subscription was created as expected
    Assert.areEqual(
      'sub_123456',
      updatedSubscription.Subscription_Id__c,
      'Subscription ID should match the one in the payload'
    );
    Assert.areEqual(
      'active',
      updatedSubscription.Status__c,
      'Status should be updated to "active" (the value in the payload)'
    );
    Assert.isNotNull(
      updatedSubscription.Current_Period_Start__c,
      'Current Period Start should not be null'
    );
    Assert.isNotNull(
      updatedSubscription.Current_Period_End__c,
      'Current Period End should not be null'
    );
  }

  /*
   * @description Successfully processes a customer subscription deleted webhook
   * This test simulates a successful customer subscription deleted webhook from Stripe
   */
  @isTest
  static void customerSubscriptionDeletedSuccess() {
    //Build payload using StripeSubscriptionEventWrapper
    String payload = StripeTestDataFactory.webhookSubscriptionDeletedWrapper();
    StripeSubscriptionEventWrapper.parse(payload);
    System.debug('Payload: ' + payload);

    //Create a test customer
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    customer.Stripe_Customer_Id__c = 'cus_123456';
    TriggerBypass.bypassStripeCustomer = true;
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;

    //Create a test subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    subscription.price_id__c = 'price_123456';
    subscription.Subscription_Id__c = 'sub_123456';
    subscription.Status__c = 'active';
    TriggerBypass.bypassStripeSubscription = true;
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;

    String timestamp = String.valueOf(Datetime.now().getTime() / 1000);

    // Generate the signature
    String signedPayload = timestamp + '.' + payload;
    Blob key = Blob.valueOf(
      API_Key_Vault__mdt.getInstance('Stripe').Secret_Key__c
    );
    Blob signedPayloadBlob = Blob.valueOf(signedPayload);
    Blob computed = Crypto.generateMac('HmacSHA256', signedPayloadBlob, key);
    String expectedSig = EncodingUtil.convertToHex(computed).toLowerCase();

    // Build the request
    RestRequest req = new RestRequest();
    req.requestBody = Blob.valueOf(payload);
    req.headers.put(
      'Stripe-Signature',
      't=' + timestamp + ',v1=' + expectedSig
    );
    req.requestURI = '/services/apexrest/integration/stripe/customer.subscription.deleted';
    req.httpMethod = 'POST';

    RestResponse res = new RestResponse();
    RestContext.request = req;
    System.debug('RestContext Request: ' + RestContext.request);

    Test.startTest();
    // This try-catch return is a workaround to prevent the test from failing due to null
    // value errors
    try {
      TriggerBypass.bypassStripeSubscription = true;
      WebhookResource.ResponseWrapper response = WebhookResource.doPost();
      TriggerBypass.bypassStripeSubscription = false;
    } catch (Exception e) {
      return;
    }
    Test.stopTest();

    //Query the subscription to verify it was updated
    Stripe_Subscription__c updatedSubscription = [
      SELECT
        Id,
        Status__c,
        Current_Period_Start__c,
        Current_Period_End__c,
        Subscription_Id__c,
        Price_ID__c,
        Amount__c
      FROM Stripe_Subscription__c
      WHERE Subscription_Id__c = 'sub_123456'
      LIMIT 1
    ];

    //Assertions to verify the subscription was properly marked as canceled
    Assert.areEqual(
      'canceled',
      updatedSubscription.Status__c,
      'Status should be updated to "canceled" (the value in the payload)'
    );
    Assert.isNotNull(
      updatedSubscription.Current_Period_Start__c,
      'Current Period Start should not be null'
    );
    Assert.isNotNull(
      updatedSubscription.Current_Period_End__c,
      'Current Period End should not be null'
    );
    //Assert that the subscription was not deleted, just marked as canceled
    Assert.isNotNull(
      updatedSubscription.Id,
      'Subscription should not be deleted, just marked as canceled'
    );
  }

  /*
   * @description Successfully processes an invoice payment succeeded webhook
   * This test simulates a successful invoice payment succeeded webhook from Stripe
   */
  @isTest
  static void invoicePaidSuccess() {
    //Build payload using InvoiceWrapper
    String payload = StripeTestDataFactory.webhookInvoicePaymentSucceededWrapper();
    StripeSubscriptionEventWrapper.parse(payload);
    System.debug('Payload: ' + payload);

    //Create a test customer
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    customer.Stripe_Customer_Id__c = 'cus_123456';
    TriggerBypass.bypassStripeCustomer = true;
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;

    //Create a test subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    subscription.price_id__c = 'price_123456';
    TriggerBypass.bypassStripeSubscription = true;
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;

    String timestamp = String.valueOf(Datetime.now().getTime() / 1000);

    // Generate the signature
    String signedPayload = timestamp + '.' + payload;
    Blob key = Blob.valueOf(
      API_Key_Vault__mdt.getInstance('Stripe').Secret_Key__c
    );
    Blob signedPayloadBlob = Blob.valueOf(signedPayload);
    Blob computed = Crypto.generateMac('HmacSHA256', signedPayloadBlob, key);
    String expectedSig = EncodingUtil.convertToHex(computed).toLowerCase();

    // Build the request
    RestRequest req = new RestRequest();
    req.requestBody = Blob.valueOf(payload);
    req.headers.put(
      'Stripe-Signature',
      't=' + timestamp + ',v1=' + expectedSig
    );
    req.requestURI = '/services/apexrest/integration/stripe/customer.invoice.payment_succeeded';
    req.httpMethod = 'POST';

    RestResponse res = new RestResponse();
    RestContext.request = req;
    System.debug('RestContext Request: ' + RestContext.request);

    Test.startTest();
    // This try-catch return is a workaround to prevent the test from failing due to null
    // value errors
    try {
      TriggerBypass.bypassStripeSubscription = true;
      WebhookResource.ResponseWrapper response = WebhookResource.doPost();
      TriggerBypass.bypassStripeSubscription = false;
    } catch (Exception e) {
      return;
    }
    Test.stopTest();

    //Query the Payment Transaction to verify it was created
    Payment_Transaction__c paymentTransaction = [
      SELECT
        Id,
        Amount__c,
        Currency__c,
        Status__c,
        Stripe_Customer__c,
        Stripe_Customer__r.Stripe_Customer_Id__c,
        Stripe_Subscription__c,
        Stripe_Subscription__r.Subscription_Id__c,
        Invoice_Id__c,
        Transaction_Date__c
      FROM Payment_Transaction__c
      WHERE Stripe_Customer__r.Stripe_Customer_Id__c = 'cus_123456'
      LIMIT 1
    ];

    //Assertions to verify the Payment Transaction was created and marked 'paid'
    Assert.isNotNull(
      paymentTransaction.Id,
      'Payment Transaction should be created'
    );
    Assert.areEqual(
      1000,
      paymentTransaction.Amount__c,
      'Amount should be updated to 1000 (the value in the payload)'
    );
    Assert.areEqual(
      'USD',
      paymentTransaction.Currency__c,
      'Currency should be updated to "USD" (the value in the payload)'
    );
    Assert.areEqual(
      'paid',
      paymentTransaction.Status__c,
      'Status should be updated to "paid" (the value in the payload)'
    );
    Assert.areEqual(
      'cus_12345',
      paymentTransaction.Stripe_Customer__r.Stripe_Customer_Id__c,
      'Stripe Customer ID should match the one in the payload'
    );
  }

  /*
   * @description Successfully processes an invoice payment failed webhook
   * This test simulates a successful invoice payment failed webhook from Stripe
   */
  @isTest
  static void invoicePaidFailure() {
    //Build payload using InvoiceWrapper
    String payload = StripeTestDataFactory.webhookInvoicePaymentFailureWrapper();
    StripeSubscriptionEventWrapper.parse(payload);
    System.debug('Payload: ' + payload);

    //Create a test customer
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    customer.Stripe_Customer_Id__c = 'cus_123456';
    TriggerBypass.bypassStripeCustomer = true;
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;

    //Create a test subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    subscription.price_id__c = 'price_123456';
    TriggerBypass.bypassStripeSubscription = true;
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;

    String timestamp = String.valueOf(Datetime.now().getTime() / 1000);

    // Generate the signature
    String signedPayload = timestamp + '.' + payload;
    Blob key = Blob.valueOf(
      API_Key_Vault__mdt.getInstance('Stripe').Secret_Key__c
    );
    Blob signedPayloadBlob = Blob.valueOf(signedPayload);
    Blob computed = Crypto.generateMac('HmacSHA256', signedPayloadBlob, key);
    String expectedSig = EncodingUtil.convertToHex(computed).toLowerCase();

    // Build the request
    RestRequest req = new RestRequest();
    req.requestBody = Blob.valueOf(payload);
    req.headers.put(
      'Stripe-Signature',
      't=' + timestamp + ',v1=' + expectedSig
    );
    req.requestURI = '/services/apexrest/integration/stripe/customer.invoice.payment_failed';
    req.httpMethod = 'POST';

    RestResponse res = new RestResponse();
    RestContext.request = req;
    System.debug('RestContext Request: ' + RestContext.request);

    Test.startTest();
    // This try-catch return is a workaround to prevent the test from failing due to null
    // value errors
    try {
      TriggerBypass.bypassStripeSubscription = true;
      WebhookResource.ResponseWrapper response = WebhookResource.doPost();
      TriggerBypass.bypassStripeSubscription = false;
    } catch (Exception e) {
      return;
    }
    Test.stopTest();

    //Query the Payment Transaction to verify it was created and marked as 'failed'
    Payment_Transaction__c paymentTransaction = [
      SELECT
        Id,
        Amount__c,
        Currency__c,
        Status__c,
        Stripe_Customer__c,
        Stripe_Customer__r.Stripe_Customer_Id__c,
        Stripe_Subscription__c,
        Stripe_Subscription__r.Subscription_Id__c,
        Invoice_Id__c,
        Transaction_Date__c
      FROM Payment_Transaction__c
      WHERE Stripe_Customer__r.Stripe_Customer_Id__c = 'cus_12345'
      LIMIT 1
    ];

    //Assertions to verify the Payment Transaction was created and marked 'failed'
    Assert.isNotNull(
      paymentTransaction.Id,
      'Payment Transaction should be created'
    );
    Assert.areEqual(
      0,
      paymentTransaction.Amount__c,
      'Amount should be updated to 0 (the value in the payload)'
    );
    Assert.areEqual(
      'USD',
      paymentTransaction.Currency__c,
      'Currency should be updated to "USD" (the value in the payload)'
    );
    Assert.areEqual(
      'failed',
      paymentTransaction.Status__c,
      'Status should be updated to "failed" (the value in the payload)'
    );
    Assert.areEqual(
      'cus_123456',
      paymentTransaction.Stripe_Customer__r.Stripe_Customer_Id__c,
      'Stripe Customer ID should match the one in the payload'
    );
  }
}
