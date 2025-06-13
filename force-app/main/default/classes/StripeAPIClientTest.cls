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
  // =============================Subscription Tests===================================

  /* description: Test for successful creation of a Stripe subscription.
   */
  @isTest
  static void createSubscriptionSuccess() {
    //Create test data
    SubscriptionsWrapper createSubscriptionWrapper = StripeTestDataFactory.createSubscriptionWrapper(
      'cus_12345',
      'price_12345'
    );

    //Set mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createSuccessSubscriptionCreationResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    // Call the method to test
    StripeAPIClient.createSubscription(createSubscriptionWrapper);
    Test.stopTest();

    //Assertions to verify response
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('sub_12345'),
      'Response body should contain the subscription ID'
    );
  }

  /* description: Test for failure in creating a Stripe subscription due to invalid price.
   */
  @isTest
  static void createSubscriptionFailure() {
    Boolean exceptionThrown = false;

    //Create test data
    SubscriptionsWrapper createSubscriptionWrapper = StripeTestDataFactory.createSubscriptionWrapper(
      'sub_12345',
      'price_invalid'
    );

    //Set mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createErrorSubscriptionCreationResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);
    try {
      Test.startTest();
      StripeAPIClient.createSubscription(createSubscriptionWrapper);
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

    //Assertions to verify error response
    Assert.areEqual(mockResponse.statusCode, 400, 'Status code should be 400');
    Assert.areEqual(
      mockResponse.status,
      'Bad Request',
      'Response status should be Bad Request'
    );
    Assert.isTrue(
      mockResponse.body.contains('error'),
      'Response body should contain error message for invalid price'
    );
  }

  /* description: Test for successful update of a Stripe subscription.
   */
  @isTest
  static void updateSubscriptionSuccess() {
    //Create Test Data
    SubscriptionsWrapper updateSubscriptionsWrapper = StripeTestDataFactory.updateSubscriptionWrapper(
      'sub_12345',
      'price_12345'
    );

    //Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createSuccessSubscriptionUpdateResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    StripeAPIClient.updateSubscription(updateSubscriptionsWrapper);
    Test.stopTest();

    //Assertions to verify update was successful
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('sub_12345'),
      'Response body should contain the updated subscription ID'
    );
  }

  /* description: Test for failure in updating a Stripe subscription due to invalid data.
   */
  @isTest
  static void updateSubscriptionFailure() {
    Boolean exceptionThrown = false;
    //Create Test Data
    SubscriptionsWrapper updateSubscriptionsWrapper = StripeTestDataFactory.updateSubscriptionWrapper(
      'sub_12345',
      'price_12345'
    );

    //Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createErrorSubscriptionUpdateResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    try {
      Test.startTest();
      StripeAPIClient.updateSubscription(updateSubscriptionsWrapper);
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
