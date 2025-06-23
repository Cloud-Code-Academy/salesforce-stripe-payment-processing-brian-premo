@isTest
private class WebhookResourceTest {
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
    System.assert(isValid, 'Signature should be valid');
  }

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
    System.assert(!isValid, 'Signature should be invalid');
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

    // Call your webhook processor
    StripeWebhookProcessor processor = new StripeWebhookProcessor();
    Test.startTest();
    processor.process(req);
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
}
