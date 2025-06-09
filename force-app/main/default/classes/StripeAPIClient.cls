/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Handles all interactions with the Stripe API.
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-05
 * LAST EDITED :
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-05 v1.0.0 Initial creation
 * -----------------------------------------------------------------------------
 */
public with sharing class StripeAPIClient {
  private static final String NAMED_CREDENTIAL = 'Stripe_NC';

  /*
  description: Makes a callout to the Stripe API to create a customer.
  @return: StripeCustomerWrapper - A wrapper object containing the response from the Stripe API.
  */
  public static StripeCustomerWrapper createCustomer(
    StripeCustomerWrapper.CustomerRequest customer
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Stripe_NC/customers');
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    req.setBody(toUrlEncodedString(customer));

    // Log the HTTP callout details
    Logger.debug(
      'HTTP Callout to Stripe API: ' +
        req.getEndpoint() +
        ' HTTP Callout Method: ' +
        req.getMethod() +
        ' HTTP Callout Body: ' +
        req.getBody()
    );

    Http http = new Http();
    HttpResponse response = http.send(req);

    if (response.getStatusCode() < 200 || response.getStatusCode() > 299) {
      Logger.error(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
      Logger.saveLog();
      throw new CalloutException(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
    }
    Logger.debug(
      'HTTP Callout successful: ' +
        response.getStatusCode() +
        ' HTTP Callout response: ' +
        response.getBody()
    );
    Logger.saveLog();
    StripeCustomerWrapper wrapper = StripeCustomerWrapper.parse(
      response.getBody()
    );
    return wrapper;
  }

  /*
  description: Makes a callout to the Stripe API to create a subscription. 
  Note that in order to create a subscription, you must first create a customer, price, and product in Stripe.
  @return: SubscriptionsWrapper - A wrapper object containing the response from the Subscription Endpoint .
  */
  public static SubscriptionsWrapper createSubscription(
    SubscriptionsWrapper subscription
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Stripe_NC/subscriptions');
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    req.setBody(subscription.toFormCreateSubBody());

    // Log the HTTP callout details
    Logger.debug(
      'HTTP Callout to Stripe API: ' +
        req.getEndpoint() +
        ' HTTP Callout Method: ' +
        req.getMethod() +
        ' HTTP Callout Body: ' +
        req.getBody()
    );

    Http http = new Http();
    HttpResponse response = http.send(req);

    if (response.getStatusCode() < 200 || response.getStatusCode() > 299) {
      Logger.error(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
      Logger.saveLog();
      throw new CalloutException(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
    }

    Logger.debug(
      'HTTP Callout to Subscriptions Endpoint successful: ' +
        response.getStatusCode() +
        ' HTTP Callout to Subscriptions Endpoint response: ' +
        response.getBody()
    );
    Logger.saveLog();

    SubscriptionsWrapper wrapper = SubscriptionsWrapper.parse(
      response.getBody()
    );
    return wrapper;
  }

  /*
  description: Makes a callout to the Stripe API to create a product.
  @param productName: String - The name of the product to be created.
  @return: String - The ID of the created product.
  */
  public static String createProduct(String productName) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Stripe_NC/products');
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    req.setBody('name=' + EncodingUtil.urlEncode(productName, 'UTF-8'));

    // Log the HTTP callout details
    Logger.debug(
      'HTTP Callout to Stripe API: ' +
        req.getEndpoint() +
        ' HTTP Callout Method: ' +
        req.getMethod() +
        ' HTTP Callout Body: ' +
        req.getBody()
    );

    Http http = new Http();
    HttpResponse response = http.send(req);

    if (response.getStatusCode() < 200 || response.getStatusCode() > 299) {
      Logger.error(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
      Logger.saveLog();
      throw new CalloutException(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
    }
    Logger.debug(
      'HTTP Callout to Product Endpoint successful: ' +
        response.getStatusCode() +
        ' HTTP Callout to Product Endpoint response: ' +
        response.getBody()
    );
    Logger.saveLog();

    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
      response.getBody()
    );
    return (String) responseMap.get('id');
  }

  /*
  description: Makes a callout to the Stripe API to create a price for a product.
  @param productId: String - The ID of the product for which the price is being created.
  @return: String - The ID of the created price.
  */
  public static String createPrice(
    String productId,
    Decimal amount,
    String currencyCode,
    String interval
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Stripe_NC/prices');
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    req.setBody(
      'product=' +
        EncodingUtil.urlEncode(productId, 'UTF-8') +
        '&unit_amount=' +
        String.valueOf(amount) +
        '&currency=' +
        EncodingUtil.urlEncode(currencyCode, 'UTF-8') +
        '&recurring[interval]=' +
        EncodingUtil.urlEncode(interval, 'UTF-8')
    );

    // Log the HTTP callout details
    Logger.debug(
      'HTTP Callout to Stripe API: ' +
        req.getEndpoint() +
        ' HTTP Callout Method: ' +
        req.getMethod() +
        ' HTTP Callout Body: ' +
        req.getBody()
    );

    Http http = new Http();
    HttpResponse response = http.send(req);

    if (response.getStatusCode() < 200 || response.getStatusCode() > 299) {
      Logger.error(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
      Logger.saveLog();
      throw new CalloutException(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
    }
    Logger.debug(
      'HTTP Price Endpoint Callout successful: ' +
        response.getStatusCode() +
        ' HTTP Price Endpoint Callout response: ' +
        response.getBody()
    );
    Logger.saveLog();

    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
      response.getBody()
    );
    return (String) responseMap.get('id');
  }

  /*
  description: Updates an existing Stripe subscription.
  @param stripeSubscriptionId: Id - The ID of the Stripe subscription to be updated
  @param priceId: Id - The ID of the new price to be applied to the subscription.
  @param prorationBehavior: String - The proration behavior to be applied during the update.
  @return: String - The response body from the Stripe API after the update.
  */
  //
  public static SubscriptionsWrapper updateSubscription(
    SubscriptionsWrapper subscription
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Stripe_NC/subscriptions/' + subscription.id);
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');

    // Prepare the body for the update request. Include stripe subscription ID, new price ID, and proration behavior if provided.
    String body = subscription.toFormUpdateSubBody();

    req.setBody(body);

    // Log the HTTP callout details
    Logger.debug(
      'HTTP Callout to Stripe API: ' +
        req.getEndpoint() +
        ' HTTP Callout Method: ' +
        req.getMethod() +
        ' HTTP Callout Body: ' +
        req.getBody()
    );

    Http http = new Http();
    HttpResponse response = http.send(req);

    if (response.getStatusCode() < 200 || response.getStatusCode() > 299) {
      Logger.error(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
      Logger.saveLog();
      throw new CalloutException(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
    }
    SubscriptionsWrapper wrapper = SubscriptionsWrapper.parse(
      response.getBody()
    );

    Logger.debug(
      'HTTP Callout successful: ' +
        response.getStatusCode() +
        ' HTTP Callout response: ' +
        response.getBody()
    );
    Logger.saveLog();

    return wrapper;
  }

  public static SubscriptionsWrapper cancelSubscription(String subscriptionId) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Stripe_NC/subscriptions/' + subscriptionId);
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('DELETE');

    // Log the HTTP callout details
    Logger.debug(
      'HTTP Callout to Stripe API: ' +
        req.getEndpoint() +
        ' HTTP Callout Method: ' +
        req.getMethod() +
        ' HTTP Callout Body: ' +
        req.getBody()
    );

    Http http = new Http();
    HttpResponse response = http.send(req);

    if (response.getStatusCode() < 200 || response.getStatusCode() > 299) {
      Logger.error(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
      Logger.saveLog();
      throw new CalloutException(
        'Error with HTTP Callout: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
    }

    Logger.debug(
      'HTTP Callout successful: ' +
        response.getStatusCode() +
        ' HTTP Callout response: ' +
        response.getBody()
    );
    Logger.saveLog();

    SubscriptionsWrapper wrapper = SubscriptionsWrapper.parse(
      response.getBody()
    );
    return wrapper;
  }

  /*
    description: Helper class that converts the customer request to a URL-encoded string
    @return: String - The URL-encoded string representation of the customer request
    This method encodes the name, email, and phone fields to be used in a URL query string.
    Example output: "name=John%20Doe&email=john.doe%40example.com&phone=1234567890"
    */
  public static String toUrlEncodedString(
    StripeCustomerWrapper.CustomerRequest customerRequest
  ) {
    String name = customerRequest.name;
    String email = customerRequest.email;
    String phone = customerRequest.phone;
    String encodedString = '';
    if (name != null) {
      encodedString += 'name=' + EncodingUtil.urlEncode(name, 'UTF-8') + '&';
    }
    if (email != null) {
      encodedString += 'email=' + EncodingUtil.urlEncode(email, 'UTF-8') + '&';
    }
    if (phone != null) {
      encodedString += 'phone=' + EncodingUtil.urlEncode(phone, 'UTF-8') + '&';
    }
    return encodedString;
  }
}
