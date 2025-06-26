/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Test class for StripeCustomerTrigger to validate customer creation and error handling.
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-12
 * LAST EDITED :
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-12 v1.0.0 Initial creation
 *  - 2025-06-25 v1.0.1 Added test for customer update
 * -----------------------------------------------------------------------------
 */
@isTest
private class StripeCustomerTriggerTest {
  /* description: Test for successful insertion of a Stripe customer.
   * This test verifies that a customer can be created successfully and the
   * Stripe_Customer_ID__c field is populated correctly.
   */
  @isTest
  static void insertCustomerSuccess() {
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();

    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createSuccessCustomerResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    insert customer;
    Test.stopTest();

    // Retrieve the new customer
    Stripe_Customer__c insertedCustomer = [
      SELECT Id, Stripe_Customer_ID__c, Name
      FROM Stripe_Customer__c
      WHERE Id = :customer.Id
      LIMIT 1
    ];

    // Assertions to verify customer was created successfully
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.isTrue(
      mockResponse.body.contains('cus_123456'),
      'Response body should contain the created customer ID'
    );
    Assert.isTrue(
      insertedCustomer.Stripe_Customer_ID__c != null,
      'Inserted customer should have a valid Stripe_Customer_ID__c'
    );
  }

  /* description: Test for failure in inserting a Stripe customer due to invalid data.
   * This test verifies that an error is thrown when trying to create a customer with invalid email.
   */
  @isTest
  static void insertCustomerFailure() {
    Boolean exceptionThrown = false;
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();

    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createErrorCustomerResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    insert customer;
    Test.stopTest();

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

  /* description: Test for successful update of a Stripe customer.
   * This test verifies that an existing customer can be updated successfully and the
   * Stripe_Customer_ID__c field remains unchanged.
   */
  @isTest
  static void updateCustomerSuccess() {
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    TriggerBypass.bypassStripeCustomer = true;
    customer.Stripe_Customer_ID__c = 'cus_123456';
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;
    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createSuccessCustomerUpdateResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);
    Test.startTest();
    customer.Name__c = 'Test Customer Update';
    update customer;
    Test.stopTest();
    // Retrieve the updated customer
    Stripe_Customer__c updatedCustomer = [
      SELECT Id, Stripe_Customer_ID__c, Name__c
      FROM Stripe_Customer__c
      WHERE Id = :customer.Id
      LIMIT 1
    ];
    // Assertions to verify customer was updated successfully
    Assert.areEqual(mockResponse.statusCode, 200, 'Status code should be 200');
    Assert.areEqual(mockResponse.status, 'OK', 'Response status should be OK');
    Assert.isNotNull(mockResponse.body, 'Response body should not be null');
    Assert.areEqual(
      updatedCustomer.Name__c,
      'Test Customer Update',
      'Updated customer name should match the new name'
    );
  }

  static void updateCustomerFailure() {
    Boolean exceptionThrown = false;
    // Create Test Data
    Stripe_Customer__c customer = StripeTestDataFactory.createStripeCustomer();
    TriggerBypass.bypassStripeCustomer = true;
    customer.Stripe_Customer_ID__c = 'cus_123456';
    insert customer;
    TriggerBypass.bypassStripeCustomer = false;

    // Set Mock
    StripeMockHttpResponse mockResponse = StripeMockHttpResponse.createErrorCustomerResponse();
    Test.setMock(HttpCalloutMock.class, mockResponse);

    Test.startTest();
    try {
      customer.Email__c = 'invalid-email';
      update customer;
    } catch (Exception e) {
      exceptionThrown = true;
    }
    Test.stopTest();

    // Assertions to verify error response
    Assert.isTrue(
      exceptionThrown,
      'Exception should be thrown for invalid email'
    );
    Assert.areEqual(mockResponse.statusCode, 400, 'Status code should be 400');
    Assert.areEqual(
      mockResponse.status,
      'Bad Request',
      'Response status should be Bad Request'
    );
  }
}
