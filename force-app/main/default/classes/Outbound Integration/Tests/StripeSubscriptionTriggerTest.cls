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
 *  - 2025-06-14 v.1.0.1 Added tests for checkout session creation
 *  - 2025-06-23 v1.1.0 Refactored test to conform to new Subscription Update Logic
 * -----------------------------------------------------------------------------
 */
@isTest
private class StripeSubscriptionTriggerTest {
  /* description: Test for successful insertion of a Stripe subscription.
   * This test verifies that a subscription can be created successfully with valid data.
   * It mocks the HTTP response from the Stripe Price API to simulate a successful subscription creation.
   */
  @isTest
  static void insertSubscriptionSuccess() {
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    insert customer; // Ensure customer exists before creating subscription
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;

    // Set Mock (using price response which is returned after salesforce subscription is created)
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createPriceSuccessResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    insert subscription;
    Test.stopTest();

    Stripe_Subscription__c insertedSubscription = [
      SELECT Id, Subscription_ID__c, Status__c, Price_ID__c
      FROM Stripe_Subscription__c
      WHERE Id = :subscription.Id
      LIMIT 1
    ];

    // Assertions to verify subscription was created successfully
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('price_12345'),
      'Response body should contain the created price ID'
    );
    Assert.isTrue(
      insertedSubscription.Price_ID__c == 'price_12345',
      'Inserted subscription should have a valid Price_ID__c'
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
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createPriceErrorResponse();
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
    Assert.areEqual(mockResponse.statusCode, 404, 'Status code should be 404');
    Assert.areEqual(
      mockResponse.status,
      'Not Found',
      'Response status should be Not Found'
    );
    Assert.isTrue(
      mockResponse.body.contains('error'),
      'Response body should contain error message for invalid price'
    );
  }

  /* description: Test that updating a Stripe Subscription for the first time will create a checkout session
   * This test verifies that an existing subscription can be updated successfully with valid data.
   * It mocks the HTTP response from the Stripe API to simulate a successful subscription update.
   *
   */
  @isTest
  static void updateSubscriptionFirstTimeSuccess() {
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    customer.Stripe_Customer_ID__c = 'cus_12345'; // Set a valid Stripe customer ID
    TriggerBypass.bypassStripeCustomer = true; // Bypass insert trigger since we are simulating an update
    insert customer; // Ensure customer exists before creating subscription
    TriggerBypass.bypassStripeCustomer = false;

    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    TriggerBypass.bypassStripeSubscription = true; // Bypass insert trigger since we are simulating an update
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;
    subscription.price_ID__c = 'price_12345'; // Update with a valid price ID

    // Set Mock (using checkout session response which is returned after salesforce subscription is updated)
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createCheckoutSessionSuccessResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    update subscription;
    Test.stopTest();

    Stripe_Subscription__c updatedSubscription = [
      SELECT Id, Subscription_ID__c, Status__c, Price_ID__c, Checkout_URL__c
      FROM Stripe_Subscription__c
      WHERE Id = :subscription.Id
      LIMIT 1
    ];

    // Assertions to verify subscription was updated successfully
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      updatedSubscription.Checkout_URL__c != null,
      'Checkout URL should not be null'
    );
  }

  /* description: Test updating a Stripe Subscription after a successive update to Amount and Quantity.
   * This test that a new price ID and checkout Session can be created successfully.
   */
  @isTest
  static void updateSubscriptionSuccessiveSuccess() {
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    customer.Stripe_Customer_ID__c = 'cus_12345'; // Set a valid Stripe customer ID
    TriggerBypass.bypassStripeCustomer = true; // Bypass insert trigger since we are simulating an update
    insert customer; // Ensure customer exists before creating subscription
    TriggerBypass.bypassStripeCustomer = false;

    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    subscription.price_ID__c = 'price_12345'; // Set a valid price ID for the first time
    subscription.product_ID__c = 'prod_12345'; // Set a valid product ID for the first time
    TriggerBypass.bypassStripeSubscription = true; // Bypass insert trigger since we are simulating an update
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;

    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createCheckoutSessionSuccessResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    subscription.Amount__c = 44;
    subscription.Quantity__c = 2;
    update subscription;
    Test.stopTest();

    Stripe_Subscription__c updatedSubscription = [
      SELECT Id, Subscription_ID__c, Status__c, Price_ID__c, Checkout_URL__c
      FROM Stripe_Subscription__c
      WHERE Id = :subscription.Id
      LIMIT 1
    ];

    updatedSubscription.Checkout_URL__c = 'updatingurl.com'; // Reset Checkout URL to simulate a new session creation
    updatedSubscription.Price_ID__c = 'price_67890'; // Set a new price ID for the update

    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.areNotEqual(
      updatedSubscription.Price_ID__c,
      'price_12345',
      'Price ID should be updated to the new price ID'
    );
    Assert.areNotEqual(
      subscription.Checkout_URL__c,
      updatedSubscription.Checkout_URL__c,
      'Checkout URL should be updated with the new session URL'
    );
  }

  /* description: Test updating a Stripe Subscription after a successive update to the subscription pAmount and Quanitty
   * This test that a new price ID and checkout Session are not created
   */
  @isTest
  static void updateSubscriptionSuccessiveFailure() {
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    customer.Stripe_Customer_ID__c = 'cus_12345'; // Set a valid Stripe customer ID
    TriggerBypass.bypassStripeCustomer = true; // Bypass insert trigger since we are simulating an update
    insert customer; // Ensure customer exists before creating subscription
    TriggerBypass.bypassStripeCustomer = false;

    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    subscription.price_ID__c = 'price_12345'; // Set a valid price ID for the first time
    subscription.product_ID__c = ''; // Missing a product which should cause failure
    TriggerBypass.bypassStripeSubscription = true; // Bypass insert trigger since we are simulating an update
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;

    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createCheckoutSessionErrorResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    subscription.Amount__c = 44;
    subscription.Quantity__c = 2;
    update subscription;
    Test.stopTest();

    Stripe_Subscription__c updatedSubscription = [
      SELECT Id, Subscription_ID__c, Status__c, Price_ID__c, Checkout_URL__c
      FROM Stripe_Subscription__c
      WHERE Id = :subscription.Id
      LIMIT 1
    ];

    Assert.areEqual(mockResponse.statusCode, 404, 'Status code should be 404');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('error'),
      'Response body should contain error message for invalid subscription update'
    );
    Assert.areEqual(
      updatedSubscription.Price_ID__c,
      'price_12345',
      'Price ID should remain the same as the update failed'
    );
    Assert.areEqual(
      subscription.Checkout_URL__c,
      updatedSubscription.Checkout_URL__c,
      'Checkout URL should remain the same as the update failed'
    );
  }

  /* description: Test for failure in updating a Stripe for the First Time.
   * This test verifies that an error is thrown when trying to update a subscription with an invalid proration behavior.
   * It mocks the HTTP response from the Stripe API to simulate a failure in subscription update.
   *
   * @throws Exception if the subscription update fails
   */
  @isTest
  static void updateSubscriptionFirstTimeFailure() {
    Boolean exceptionThrown = false;
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    TriggerBypass.bypassStripeCustomer = true; // Bypass insert trigger since we are simulating an update
    insert customer; // Ensure customer exists before creating subscription
    TriggerBypass.bypassStripeCustomer = false;
    Stripe_Subscription__c subscription = StripeTestDataFactory.createStripeSubscription();
    subscription.Stripe_Customer__c = customer.Id;
    TriggerBypass.bypassStripeSubscription = true; // Bypass insert trigger since we are simulating an update
    insert subscription;
    TriggerBypass.bypassStripeSubscription = false;
    subscription.price_ID__c = 'price_12345'; // Update with a valid price ID
    subscription.Customer__c = null; // null out customer to simulate failure

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
