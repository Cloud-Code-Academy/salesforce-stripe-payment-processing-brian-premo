/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Webhook processor for incoming Stripe events
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-22
 * LAST EDITED :
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-05 v1.0.0 Initial creation
 * -----------------------------------------------------------------------------
 */
public without sharing class StripeWebhookProcessor implements IWebhookProcessor {
  //Constants for webhook event types
  private static final String EVENT_CUSTOMER_UPDATED = 'customer.updated';
  private static final String EVENT_SUBSCRIPTION_CREATED = 'customer.subscription.created';
  private static final String EVENT_SUBSCRIPTION_UPDATED = 'customer.subscription.updated';
  private static final String EVENT_SUBSCRIPTION_DELETED = 'customer.subscription.deleted';
  private static final String EVENT_INVOICE_PAYMENT_SUCCEEDED = 'invoice.payment_succeeded';
  private static final String EVENT_INVOICE_PAYMENT_FAILED = 'invoice.payment_failed';

  public static Boolean validate(RestRequest request) {
    // Verify HMAC signature using HMAC-SHA256 for Stripe webhook
    String signatureHeader = request.headers.get('Stripe-Signature'); //Example: t=1234567890,v1=abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
    if (String.isBlank(signatureHeader)) {
      return false;
    }

    // Parse the signature header to extract timestamp and signature
    Map<String, String> sigMap = parseStripeSignatureHeader(signatureHeader);
    if (!sigMap.containsKey('t') || !sigMap.containsKey('v1')) {
      return false; // Invalid signature format
    }

    String timestamp = sigMap.get('t');
    String signature = sigMap.get('v1');

    String payload = request.requestBody.toString();
    String signedPayload = timestamp + '.' + payload;

    Blob key = Blob.valueOf(
      API_Key_Vault__mdt.getInstance('Stripe').Secret_Key__c
    );
    Blob signedPayloadBlob = Blob.valueOf(signedPayload);
    // Generate HMAC-SHA256 signature
    Blob computed = Crypto.generateMac('HmacSHA256', signedPayloadBlob, key);
    String expectedSig = EncodingUtil.convertToHex(computed).toLowerCase();

    if (expectedSig == null || signature == null) {
      return false; // If either is null, return false
    } else if (expectedSig == signature) {
      return true;
    } else {
      return false;
    }
  }

  private static Map<String, String> parseStripeSignatureHeader(String header) {
    Map<String, String> result = new Map<String, String>();
    for (String part : header.split(',')) {
      List<String> pair = part.split('=');
      if (pair.size() == 2) {
        result.put(pair[0].trim(), pair[1].trim());
      }
    }
    return result;
  }

  public void process(RestRequest request) {
    String requestBody = request.requestBody.toString();
    Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
      requestBody
    );
    System.debug('REQUEST BODY RECEIVED *#$*#$*#*$*# = ' + requestBody);
    String webhookEvent = (String) payload.get('type');
    System.debug('WEBHOOK EVENT RETURNED *#$*#$*#*$*# = ' + webhookEvent);

    if (webhookEvent == EVENT_CUSTOMER_UPDATED) {
      processCustomerUpdated(payload);
    } else if (webhookEvent == EVENT_SUBSCRIPTION_UPDATED) {
      processSubscriptionUpdated(requestBody);
    } else if (webhookEvent == EVENT_SUBSCRIPTION_CREATED) {
      processSubscriptionCreated(requestBody);
    } else if (webhookEvent == EVENT_SUBSCRIPTION_DELETED) {
      processSubscriptionDeleted(requestBody);
    } else if (webhookEvent == EVENT_INVOICE_PAYMENT_SUCCEEDED) {
      processInvoicePaymentSucceeded(requestBody);
    } else if (webhookEvent == EVENT_INVOICE_PAYMENT_FAILED) {
      processInvoicePaymentFailed(requestBody);
    } else {
      throw new WebhookFactory.WebhookException(
        'Unsupported Stripe webhook event: ' + webhookEvent
      );
    }
  }

  private void processCustomerUpdated(Map<String, Object> payload) {
    // Handle customer.updated event
    Map<String, Object> customerData = (Map<String, Object>) payload.get(
      'data'
    );
    Map<String, Object> customerObject = (Map<String, Object>) customerData.get(
      'object'
    );
    Map<String, Object> invoiceSettings = (Map<String, Object>) customerObject.get(
      'invoice_settings'
    );

    //Fields to update include Customer Name, Email, Phone
    String customerId = (String) customerObject.get('id');
    String customerName = (String) customerObject.get('name');
    String customerEmail = (String) customerObject.get('email');
    String customerPhone = (String) customerObject.get('phone');
    String defaultPaymentMethod = (String) invoiceSettings.get(
      'default_payment_method'
    );

    // Query the Stripe_Customer__c record in Salesforce
    Stripe_Customer__c stripeCustomer = [
      SELECT Id, Name, Email__c, Phone__c, Default_Payment_Method__c, Name__c
      FROM Stripe_Customer__c
      WHERE Stripe_Customer_ID__c = :customerId
      LIMIT 1
    ];

    System.debug('Stripe Customer: ' + stripeCustomer);

    if (stripeCustomer != null) {
      // Update the Stripe_Customer__c record with new values
      stripeCustomer.Name__c = customerName;
      stripeCustomer.Email__c = customerEmail;
      stripeCustomer.Phone__c = customerPhone;
      stripeCustomer.Default_Payment_Method__c = defaultPaymentMethod;

      // Save the updated record
      try {
        update stripeCustomer;
        System.debug(
          'Stripe Customer updated successfully: ' + stripeCustomer.Id
        );
      } catch (DMLException e) {
        System.debug('Error updating Stripe Customer: ' + e.getMessage());
        throw new WebhookFactory.WebhookException(
          'Error updating Stripe Customer: ' + e.getMessage()
        );
      }
    }
  }

  private void processSubscriptionCreated(String requestBody) {
    //Parse the request body to get the subscription details
    StripeSubscriptionEventWrapper eventWrapper = StripeSubscriptionEventWrapper.parse(
      requestBody
    );
    String subscriptionID = eventWrapper.data.object_wrapper.id;
    System.debug('Subscription ID: ' + subscriptionID);
    System.debug('Parsed Stripe Subscription Create Event: ' + eventWrapper);

    // Extract subscription details from the event wrapper
    StripeSubscriptionEventWrapper.ObjectWrapper subscriptionObject = eventWrapper.data.object_wrapper;
    System.debug('Subscription Object: ' + subscriptionObject);

    // Query the Stripe_Subscription__c record in Salesforce using the price ID to match
    String priceID = subscriptionObject.items.data[0].price.id;
    Stripe_Subscription__c stripeSubscription = [
      SELECT
        Id,
        Status__c,
        Current_Period_Start__c,
        Current_Period_End__c,
        Price_ID__c
      FROM Stripe_Subscription__c
      WHERE Price_ID__c = :priceID
      LIMIT 1
    ];

    if (stripeSubscription != null) {
      // Update the subscription record with new values
      stripeSubscription.Subscription_ID__c = subscriptionID;
      stripeSubscription.Status__c = subscriptionObject.status;
      stripeSubscription.Current_Period_Start__c = SubscriptionsWrapper.convertUnixToDatetime(
        String.valueOf(subscriptionObject.items.data[0].current_period_start)
      );
      stripeSubscription.Current_Period_End__c = SubscriptionsWrapper.convertUnixToDatetime(
        String.valueOf(subscriptionObject.items.data[0].current_period_end)
      );

      // Save the updated record
      try {
        update stripeSubscription;
        System.debug(
          'Stripe Subscription created successfully: ' + stripeSubscription.Id
        );
      } catch (Exception e) {
        System.debug('Error updating Stripe Subscription: ' + e.getMessage());
        throw new WebhookFactory.WebhookException(
          'Error updating Stripe Subscription: ' + e.getMessage()
        );
      }
    }
  }
  private void processSubscriptionUpdated(String requestBody) {
    //Parse the request body to get the subscription details
    StripeSubscriptionEventWrapper eventWrapper = StripeSubscriptionEventWrapper.parse(
      requestBody
    );
    String subscriptionID = eventWrapper.data.object_wrapper.id;
    System.debug('Subscription ID: ' + subscriptionID);
    System.debug('Parsed Stripe Subscription Update Event: ' + eventWrapper);

    // Extract subscription details from the event wrapper
    StripeSubscriptionEventWrapper.ObjectWrapper subscriptionObject = eventWrapper.data.object_wrapper;

    System.debug('Subscription Object: ' + subscriptionObject);

    // Query the Stripe_Subscription__c record in Salesforce
    Stripe_Subscription__c stripeSubscription = [
      SELECT
        Id,
        Status__c,
        Current_Period_Start__c,
        Current_Period_End__c,
        Quantity__c,
        Amount__c,
        Price_ID__c
      FROM Stripe_Subscription__c
      WHERE Subscription_ID__c = :subscriptionID
      LIMIT 1
    ];

    if (stripeSubscription != null) {
      // Update the subscription record with new values
      stripeSubscription.Quantity__c = subscriptionObject.items.data[0]
        .quantity;
      stripeSubscription.Amount__c =
        subscriptionObject.items.data[0].price.unit_amount / 100; //Convert to dollars
      stripeSubscription.Status__c = subscriptionObject.status;
      stripeSubscription.Price_ID__c = subscriptionObject.items.data[0]
        .price.id;
      stripeSubscription.Current_Period_Start__c = SubscriptionsWrapper.convertUnixToDatetime(
        String.valueOf(subscriptionObject.items.data[0].current_period_start)
      );
      stripeSubscription.Current_Period_End__c = SubscriptionsWrapper.convertUnixToDatetime(
        String.valueOf(subscriptionObject.items.data[0].current_period_end)
      );
      stripeSubscription.Price_ID__c = subscriptionObject.items.data[0]
        .price.id;

      // Save the updated record
      try {
        update stripeSubscription;
        System.debug(
          'Stripe Subscription updated successfully: ' + stripeSubscription.Id
        );
      } catch (Exception e) {
        System.debug('Error updating Stripe Subscription: ' + e.getMessage());
        throw new WebhookFactory.WebhookException(
          'Error updating Stripe Subscription: ' + e.getMessage()
        );
      }
    }
  }

  private void processSubscriptionDeleted(String requestBody) {
    // Handle customer.subscription.deleted event
    // Implement logic to mark subscription in Salesforce Cancelled. Also update start and end date
    StripeSubscriptionEventWrapper eventWrapper = StripeSubscriptionEventWrapper.parse(
      requestBody
    );
    String subscriptionID = eventWrapper.data.object_wrapper.id;

    System.debug('Subscription ID: ' + subscriptionID);
    System.debug('Parsed Stripe Subscription Delete Event: ' + eventWrapper);

    // Extract subscription details from the event wrapper
    StripeSubscriptionEventWrapper.ObjectWrapper subscriptionObject = eventWrapper.data.object_wrapper;

    // Query the Stripe_Subscription__c record in Salesforce
    Stripe_Subscription__c stripeSubscription = [
      SELECT Id, Status__c, Current_Period_Start__c, Current_Period_End__c
      FROM Stripe_Subscription__c
      WHERE Subscription_ID__c = :subscriptionID
      LIMIT 1
    ];
    if (stripeSubscription != null) {
      // Update the subscription record to mark it as cancelled
      stripeSubscription.Status__c = 'Canceled';
      stripeSubscription.Current_Period_Start__c = SubscriptionsWrapper.convertUnixToDatetime(
        String.valueOf(subscriptionObject.items.data[0].current_period_start)
      );
      stripeSubscription.Current_Period_End__c = SubscriptionsWrapper.convertUnixToDatetime(
        String.valueOf(subscriptionObject.items.data[0].current_period_end)
      );

      // Save the updated record
      try {
        update stripeSubscription;
        System.debug(
          'Stripe Subscription marked as cancelled: ' + stripeSubscription.Id
        );
      } catch (Exception e) {
        System.debug('Error updating Stripe Subscription: ' + e.getMessage());
        throw new WebhookFactory.WebhookException(
          'Error updating Stripe Subscription: ' + e.getMessage()
        );
      }
    }
    System.debug(
      'Stripe Subscription deleted event processed successfully for ID: ' +
      subscriptionID
    );
  }

  private void processInvoicePaymentSucceeded(String requestBody) {
    Logger.debug('Processing Invoice Payment Succeeded Event: ' + requestBody);
    StripeInvoiceWrapper invoiceWrapper;
    try {
      invoiceWrapper = StripeInvoiceWrapper.parse(requestBody);
      Logger.debug(
        'Parsed Stripe Invoice Payment Failed Event: ' + invoiceWrapper
      );
    } catch (Exception ex) {
      Logger.error(
        'Failed to parse invoice payment failed event: ' + ex.getMessage()
      );
      Logger.saveLog();
      return;
    }

    //Debug Parsed Invoice Wrapper
    Logger.debug(
      'Parsed Stripe Invoice Payment Succeeded Event: ' + invoiceWrapper
    );
    Logger.saveLog();
    String invoiceId = invoiceWrapper.data.object_wrapper.id;
    String subscriptionId = invoiceWrapper.data.object_wrapper.lines.data[0]
      .parent.subscription_item_details.subscription;
    String customerId = invoiceWrapper.data.object_wrapper.customer;
    String status = invoiceWrapper.data.object_wrapper.status;
    Decimal amount = invoiceWrapper.data.object_wrapper.amount_paid / 100; // Convert to dollars
    String currencyCode = invoiceWrapper.data.object_wrapper.currency_code;
    String transactionDateUnix = invoiceWrapper.data.object_wrapper.created;
    Datetime transactionDateConverted = SubscriptionsWrapper.convertUnixToDatetime(
      transactionDateUnix
    );

    // Query the Stripe_Customer__c record in Salesforce using the customer ID
    Stripe_Customer__c stripeCustomer = [
      SELECT Id, Name__c, Email__c, Phone__c
      FROM Stripe_Customer__c
      WHERE Stripe_Customer_ID__c = :customerId
      LIMIT 1
    ];

    //Query the Stripe_Subscription__c record in Salesforce using the subscription ID
    Stripe_Subscription__c stripeSubscription = [
      SELECT Id
      FROM Stripe_Subscription__c
      WHERE Subscription_ID__c = :subscriptionId
      LIMIT 1
    ];

    Payment_Transaction__c paymentTransaction = new Payment_Transaction__c();
    paymentTransaction.Invoice_ID__c = invoiceId;
    paymentTransaction.Stripe_Subscription__c = stripeSubscription.Id;
    paymentTransaction.Stripe_Customer__c = stripeCustomer.Id;
    paymentTransaction.Status__c = status;
    paymentTransaction.Amount__c = amount;
    paymentTransaction.Currency__c = currencyCode;
    paymentTransaction.Transaction_Date__c = transactionDateConverted;

    try {
      insert paymentTransaction;
      System.debug(
        'Payment Transaction created successfully: ' + paymentTransaction.Id
      );
    } catch (Exception e) {
      Logger.error('Error creating Payment Transaction: ' + e.getMessage());
      Logger.saveLog();
      throw new WebhookFactory.WebhookException(
        'Error creating Payment Transaction: ' + e.getMessage()
      );
    }
  }

  private void processInvoicePaymentFailed(String requestBody) {
    Logger.debug('Processing Invoice Payment Failed Event: ' + requestBody);
    StripeInvoiceWrapper invoiceWrapper;

    try {
      invoiceWrapper = StripeInvoiceWrapper.parse(requestBody);
      Logger.debug(
        'Parsed Stripe Invoice Payment Failed Event: ' + invoiceWrapper
      );
    } catch (Exception ex) {
      Logger.error(
        'Failed to parse invoice payment failed event: ' + ex.getMessage()
      );
      Logger.saveLog();
      return;
    }

    Logger.saveLog();

    // Safe access using null checks (mostly doing this for safety and using Stripe CLI but the wrapper should not be null)
    String invoiceId = invoiceWrapper?.data?.object_wrapper?.id;
    String subscriptionId = invoiceWrapper
        ?.data
        ?.object_wrapper
        ?.lines
        ?.data
        ?.isEmpty() == false
      ? invoiceWrapper.data.object_wrapper.lines.data[0]
          ?.parent
          ?.subscription_item_details
          ?.subscription
      : null;
    String customerId = invoiceWrapper?.data?.object_wrapper?.customer;
    String status = 'Failed';

    Decimal amount = invoiceWrapper?.data?.object_wrapper?.amount_paid != null
      ? invoiceWrapper.data.object_wrapper.amount_paid / 100
      : null;
    String currencyCode = invoiceWrapper?.data?.object_wrapper?.currency_code;
    String transactionDateUnix = invoiceWrapper?.data?.object_wrapper?.created;
    Datetime transactionDateConverted = SubscriptionsWrapper.convertUnixToDatetime(
      transactionDateUnix
    );

    Stripe_Customer__c stripeCustomer;
    if (customerId != null) {
      try {
        stripeCustomer = [
          SELECT Id, Name__c, Email__c, Phone__c
          FROM Stripe_Customer__c
          WHERE Stripe_Customer_ID__c = :customerId
          LIMIT 1
        ];
      } catch (Exception ex) {
        Logger.error('Customer lookup failed: ' + ex.getMessage());
      }
    }

    Stripe_Subscription__c stripeSubscription;
    if (subscriptionId != null) {
      try {
        stripeSubscription = [
          SELECT Id
          FROM Stripe_Subscription__c
          WHERE Subscription_ID__c = :subscriptionId
          LIMIT 1
        ];
      } catch (Exception ex) {
        Logger.error('Subscription lookup failed: ' + ex.getMessage());
      }
    }

    Payment_Transaction__c paymentTransaction = new Payment_Transaction__c();
    if (invoiceId != null) {
      paymentTransaction.Invoice_ID__c = invoiceId;
    }
    if (stripeSubscription != null) {
      paymentTransaction.Stripe_Subscription__c = stripeSubscription.Id;
    }
    if (stripeCustomer != null) {
      paymentTransaction.Stripe_Customer__c = stripeCustomer.Id;
    }

    paymentTransaction.Status__c = status;

    if (amount != null) {
      paymentTransaction.Amount__c = amount;
    }
    if (currencyCode != null) {
      paymentTransaction.Currency__c = currencyCode;
    }
    if (transactionDateConverted != null) {
      paymentTransaction.Transaction_Date__c = transactionDateConverted;
    }

    try {
      insert paymentTransaction;
      Logger.debug(
        'Payment Transaction created successfully: ' + paymentTransaction.Id
      );
    } catch (Exception e) {
      Logger.error('Error creating Payment Transaction: ' + e.getMessage());
      throw new WebhookFactory.WebhookException(
        'Error creating Payment Transaction: ' + e.getMessage()
      );
    }

    Logger.saveLog();
  }
}
