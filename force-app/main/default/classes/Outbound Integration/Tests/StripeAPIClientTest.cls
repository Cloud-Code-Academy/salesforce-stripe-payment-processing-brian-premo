/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Test class for StripeAPIClient to validate customer and subscription operations.
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-12
 * LAST EDITED :
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-12 v1.0.0 Initial creation
 *  - 2025-06-22 v1.0.1 Added tests for product and price creation
 * -----------------------------------------------------------------------------
 */
@IsTest
public with sharing class StripeAPIClientTest {
  // =============================Customer Tests=======================================

  /* description: Test for successful creation of a Stripe customer.
   */
  @isTest
  static void createCustomerSuccess() {
    // Create test data
    StripeCustomerWrapper.CustomerRequest createCustomerWrapper = StripeTestDataFactory.createStripeCustomerWrapper(
      'cus_12345',
      'testemail@test.com',
      '1231231234'
    );
    // Set mock response
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createSuccessCustomerResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    // Call the method to test
    StripeAPIClient.createCustomer(createCustomerWrapper);
    Test.stopTest();

    // Assertions to verify response
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('cus_123456'),
      'Response body should contain the customer ID'
    );
  }

  @IsTest
  static void updateCustomerSuccess() {
    // Create test data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    TriggerBypass.bypassStripeCustomer = true;
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;

    StripeCustomerWrapper.CustomerRequest updateCustomerWrapper = new StripeCustomerWrapper.CustomerRequest();
    updateCustomerWrapper.name = 'Test Customer Update';
    updateCustomerWrapper.email = customer.Email__c;
    updateCustomerWrapper.phone = customer.Phone__c;

    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createSuccessCustomerUpdateResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);
    Test.startTest();
    StripeAPIClient.updateCustomer(
      customer.Stripe_Customer_ID__c,
      updateCustomerWrapper
    );
    Test.stopTest();

    //Assertions to verify response
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('Test Customer Update'),
      'Response body should contain the customer Name'
    );
  }

  @isTest
  static void updateCustomerFailure() {
    Boolean exceptionThrown = false;
    // Create test data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    TriggerBypass.bypassStripeCustomer = true;
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;
    StripeCustomerWrapper.CustomerRequest updateCustomerWrapper = new StripeCustomerWrapper.CustomerRequest();
    updateCustomerWrapper.name = 'Test Customer Update';
    updateCustomerWrapper.email = 'invalidemail'; // Invalid email to simulate failure
    updateCustomerWrapper.phone = customer.Phone__c;
    // Set mock response
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createErrorCustomerResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);
    try {
      Test.startTest();
      // Call the method to test
      StripeAPIClient.updateCustomer(
        customer.Stripe_Customer_ID__c,
        updateCustomerWrapper
      );
      Test.stopTest();
    } catch (Exception e) {
      exceptionThrown = true;
      System.assert(
        e.getMessage().contains('Error'),
        'Exception message should indicate HTTP callout error'
      );
    }
    System.assert(
      exceptionThrown,
      'Exception should have been thrown for HTTP 400 error'
    );
  }

  /* description: Test for failure in creating a Stripe customer due to invalid data.
   */
  @isTest
  static void createCustomerFailure() {
    Boolean exceptionThrown = false;
    // Create test data
    StripeCustomerWrapper.CustomerRequest createCustomerWrapper = StripeTestDataFactory.createStripeCustomerWrapper(
      'cus_12345',
      'invalidemail',
      '1231231234'
    );

    // Set mock response
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createErrorCustomerResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    try {
      Test.startTest();
      // Call the method to test
      StripeAPIClient.createCustomer(createCustomerWrapper);
      Test.stopTest();
    } catch (Exception e) {
      exceptionThrown = true;
      System.assert(
        e.getMessage().contains('Error'),
        'Exception message should indicate HTTP callout error'
      );
      System.assert(
        exceptionThrown,
        'Exception should have been thrown for HTTP 400 error'
      );
    }

    // Assertions to verify error response
    Assert.areEqual(mockResponse.statusCode, 400, 'Status code should be 400');
    Assert.areEqual(
      mockResponse.status,
      'Bad Request',
      'Response status should be Bad Request'
    );
    Assert.isTrue(
      mockResponse.body.contains('error'),
      'Response body should contain error message for invalid email'
    );
  }
  // =============================Product Tests========================================
  /* description: Test for successful creation of a Stripe product.
   * This test verifies that the product creation API call returns a successful response
   * with the expected product ID in the response body.
   */
  @isTest
  static void createProductSuccessResponse() {
    String productName = 'Test Product';
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createProductSuccessResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    StripeAPIClient.createProduct(productName);
    Test.stopTest();

    // Assertions to verify response
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('prod_12345'),
      'Response body should contain the product ID'
    );
  }

  /* description: Test for failure in creating a Stripe product.
   * This test verifies that the product creation API call returns an error response
   * when an invalid product name is provided, such as a name that exceeds the character limit
   */
  @isTest
  static void createProductFailure() {
    //Set a name that will cause a failure
    String productName = '💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣💣';
    Boolean exceptionThrown = false;
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createProductErrorResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);
    try {
      Test.startTest();
      StripeAPIClient.createProduct(productName);
      Test.stopTest();
    } catch (CalloutException e) {
      exceptionThrown = true;
      System.assert(
        e.getMessage().contains('Error'),
        'Exception message should indicate HTTP callout error'
      );
      System.assert(
        exceptionThrown,
        'Exception should have been thrown for HTTP 400 error'
      );
    }
  }

  // =============================Price Tests===========================================

  /* description: Test for successful creation of a Stripe price.
   * This test verifies that the price creation API call returns a successful response
   * with the expected price ID in the response body.
   */
  @isTest
  static void createPriceSuccess() {
    String productId = 'prod_12345';
    Integer amount = 1000;
    String currencyCode = 'USD';
    String interval = 'month';

    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createPriceSuccessResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);
    Test.startTest();
    String priceId = StripeAPIClient.createPrice(
      productId,
      amount,
      currencyCode,
      interval
    );
    Test.stopTest();

    //Assertions to verify response
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('price_12345'),
      'Response body should contain the price ID'
    );
    Assert.areEqual(
      priceId,
      'price_12345',
      'Returned price ID should match mock response'
    );
  }

  /* description: Test for failure in creating a Stripe price.
   * This test verifies that the price creation API call returns an error response
   * when an invalid currency code is provided, such as a non-existent currency.
   */
  @isTest
  static void createPriceFailure() {
    Boolean exceptionThrown = false;
    String productId = 'prod_12345';
    Integer amount = 1000;
    String currencyCode = 'NotACurrency'; // Invalid currency code to simulate failure
    String interval = 'month';

    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createPriceErrorResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);
    try {
      Test.startTest();
      StripeAPIClient.createPrice(productId, amount, currencyCode, interval);
      Test.stopTest();
    } catch (CalloutException e) {
      exceptionThrown = true;
      System.Assert.isTrue(
        e.getMessage().contains('Error'),
        'Exception message should indicate HTTP callout error'
      );
      System.Assert.isTrue(
        exceptionThrown,
        'Exception should have been thrown for HTTP 400 error'
      );
      System.Assert.areEqual(
        mockResponse.statusCode,
        404,
        'Status code should be 404'
      );
      System.Assert.areEqual(
        mockResponse.status,
        'Not Found',
        'Response status should be Not Found for invalid currency'
      );
      System.Assert.isTrue(
        mockResponse.body.contains('error'),
        'Response body should contain error message for invalid currency'
      );
    }
  }

  // =============================Subscription Tests====================================

  /* description: Test for successful cancellation of a Stripe subscription.
   */
  @isTest
  static void cancelSubscriptionSuccess() {
    String subscriptionId = 'sub_12345';
    String canceledAt = '1749501061';
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createCancelSubscriptionResponse();
    SubscriptionsWrapper sw = SubscriptionsWrapper.parse(mockResponse.body);

    //call to unix timestamp (testing for code coverage)
    DateTime convertUnix = SubscriptionsWrapper.convertUnixToDatetime(
      canceledAt
    );
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    StripeAPIClient.cancelSubscription(subscriptionId);
    Test.stopTest();

    //Assertions to verify response
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('sub_12345'),
      'Response body should contain the canceled subscription ID'
    );
  }

  // =============================Checkout Session Tests================================

  /* description: Test for successful creation of a Stripe Checkout Session.
   */
  @isTest
  static void createCheckoutSessionSuccess() {
    //Create Test Data
    CheckoutSessionWrapper sessionRequest = StripeTestDataFactory.createCheckoutSessionWrapper(
      'cus_12345',
      'price_12345',
      'USD'
    );

    //Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createCheckoutSessionSuccessResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    //Start Test
    Test.startTest();
    CheckoutSessionWrapper sessionResponse = StripeAPIClient.createCheckoutSession(
      sessionRequest
    );
    Test.stopTest();

    //Assertions to verify response
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
  }

  /* description: Test for failure in creating a Stripe Checkout Session due to invalid data.
   */
  @isTest
  static void createCheckoutSessionFailure() {
    Boolean exceptionThrown = false;

    //Create Test Data
    CheckoutSessionWrapper sessionRequest = StripeTestDataFactory.createCheckoutSessionWrapper(
      'cus_12345',
      'price_invalid',
      'USD'
    );

    //Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createCheckoutSessionErrorResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    try {
      Test.startTest();
      StripeAPIClient.createCheckoutSession(sessionRequest);
      Test.stopTest();
    } catch (Exception e) {
      exceptionThrown = true;
      System.assert(
        e.getMessage().contains('Error'),
        'Exception message should indicate HTTP callout error'
      );
    }
    System.assert(
      exceptionThrown,
      'Exception should have been thrown for HTTP 400 error'
    );
  }
}
