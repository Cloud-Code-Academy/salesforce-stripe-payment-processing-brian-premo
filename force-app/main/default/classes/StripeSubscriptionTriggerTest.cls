/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Test class for Stripe Subscription Trigger operations
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
private class StripeSubscriptionTriggerTest {
  /* description: Test for successful insertion of a Stripe subscription.
   * This test verifies that a subscription can be created successfully with valid data.
   * It mocks the HTTP response from the Stripe API to simulate a successful subscription creation.
   *
   * @throws Exception if the subscription creation fails
   */
  @isTest
  static void insertSubscriptionSuccess() {
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    insert customer; // Ensure customer exists before creating subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;

    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createSuccessSubscriptionCreationResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    insert subscription;
    Test.stopTest();

    Stripe_Subscription__c insertedSubscription = [
      SELECT Id, Subscription_ID__c, Status__c
      FROM Stripe_Subscription__c
      WHERE Id = :subscription.Id
      LIMIT 1
    ];

    // Assertions to verify subscription was created successfully
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('sub_123456'),
      'Response body should contain the created subscription ID'
    );
    Assert.isTrue(
      insertedSubscription.Subscription_ID__c != null,
      'Inserted subscription should have a valid Subscription_ID__c'
    );
  }

  /* description: Test for failure in inserting a Stripe subscription due to invalid data.
   * This test verifies that an error is thrown when trying to create a subscription with an invalid price ID.
   * It mocks the HTTP response from the Stripe API to simulate a failure in subscription creation.
   *
   * @throws Exception if the subscription creation fails
   */
  @isTest
  static void insertSubscriptionFailure() {
    Boolean exceptionThrown = false;
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    insert customer; // Ensure customer exists before creating subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscriptionFailure();
    subscription.Stripe_Customer__c = customer.Id;

    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createErrorSubscriptionCreationResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    try {
      Test.startTest();
      insert subscription;
      Test.stopTest();
    } catch (Exception e) {
      exceptionThrown = true;
      System.debug('Expected exception caught: ' + e.getMessage());
    }

    // Assertions to verify error response
    Assert.isTrue(
      exceptionThrown,
      'Exception should have been thrown for invalid price'
    );
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
   * This test verifies that an existing subscription can be updated successfully with valid data.
   * It mocks the HTTP response from the Stripe API to simulate a successful subscription update.
   *
   * @throws Exception if the subscription update fails
   */
  @isTest
  static void updateSubscriptionSuccess() {
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    insert customer; // Ensure customer exists before creating subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    insert subscription;
    subscription.price_ID__c = 'price_12345'; // Update with a valid price ID
    subscription.Propration_Behavior__c = 'always_invoice'; // Set a valid proration behavior

    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createSuccessSubscriptionCreationResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    update subscription;
    Test.stopTest();

    Stripe_Subscription__c updatedSubscription = [
      SELECT Id, Subscription_ID__c, Status__c, Price_ID__c
      FROM Stripe_Subscription__c
      WHERE Id = :subscription.Id
      LIMIT 1
    ];

    // Assertions to verify subscription was updated successfully
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('sub_12345'),
      'Response body should contain the updated subscription ID'
    );
  }

  /* description: Test for failure in updating a Stripe subscription due to invalid data.
   * This test verifies that an error is thrown when trying to update a subscription with an invalid proration behavior.
   * It mocks the HTTP response from the Stripe API to simulate a failure in subscription update.
   *
   * @throws Exception if the subscription update fails
   */
  @isTest
  static void updateSubscriptionFailure() {
    Boolean exceptionThrown = false;
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    insert customer; // Ensure customer exists before creating subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    insert subscription;
    subscription.price_ID__c = 'price_12345'; // Update with a valid price ID
    subscription.Propration_Behavior__c = 'notarealbehavior'; // Set an invalid proration behavior

    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createErrorSubscriptionCreationResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    try {
      Test.startTest();
      update subscription;
      Test.stopTest();
    } catch (Exception e) {
      exceptionThrown = true;
      System.debug('Expected exception caught: ' + e.getMessage());
    }

    // Assertions to verify error response
    Assert.isTrue(
      exceptionThrown,
      'Exception should have been thrown for invalid proration behavior'
    );
    Assert.areEqual(mockResponse.statusCode, 400, 'Status code should be 400');
    Assert.areEqual(
      mockResponse.status,
      'Bad Request',
      'Response status should be Bad Request'
    );
    Assert.isTrue(
      mockResponse.body.contains('error'),
      'Response body should contain error message for invalid proration behavior'
    );
  }

  /* description: Test for successful cancellation of a Stripe subscription.
   * This test verifies that an existing subscription can be canceled successfully.
   * It mocks the HTTP response from the Stripe API to simulate a successful subscription cancellation.
   *
   * @throws Exception if the subscription cancellation fails
   */
  @isTest
  static void cancelSubscriptionSuccess() {
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    insert customer; // Ensure customer exists before creating subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    TriggerBypass.bypassStripeSubscription = true; // Bypass insert trigger since we are simulating a cancellation
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;
    subscription.Status__c = 'Canceled'; // Set initial status to active

    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createSuccessCancelSubscriptionResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    update subscription; // Simulate cancellation by updating the subscription
    Test.stopTest();

    Stripe_Subscription__c canceledSubscription = [
      SELECT Id, Subscription_ID__c, Status__c
      FROM Stripe_Subscription__c
      WHERE Id = :subscription.Id
      LIMIT 1
    ];

    // Assertions to verify subscription was canceled successfully
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('sub_123456'),
      'Response body should contain the canceled subscription ID'
    );
    Assert.areEqual(
      canceledSubscription.Status__c,
      'Canceled',
      'Subscription status should be canceled'
    );
  }

  @isTest
  static void cancelSubscriptionFailure() {
    Boolean exceptionThrown = false;
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    insert customer; // Ensure customer exists before creating subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    TriggerBypass.bypassStripeSubscription = true; // Bypass insert trigger since we are simulating a cancellation
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;
    subscription.Status__c = 'Canceled';
    subscription.subscription_ID__c = 'subnotfound'; // Set an invalid subscription ID to simulate failure

    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createErrorCancelSubscriptionResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    update subscription; // Simulate cancellation by updating the subscription
    Test.stopTest();

    Assert.areEqual(mockResponse.statusCode, 404, 'Status code should be 400');
    Assert.isTrue(
      mockResponse.body.contains('error'),
      'Response body should contain error message for invalid cancellation'
    );
  }
}
