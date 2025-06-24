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
 *  - 2025-06-12 v1.0.1 Minor changes to improve descriptions of methods
 *  - 2025-06-22 v1.1.0 removed logic for create sub, that will be done automatically
 *  after checkout session is complete
 * -----------------------------------------------------------------------------
 */
public with sharing class StripeAPIClient {
  private static final String NAMED_CREDENTIAL = 'Stripe_NC';

  /*
  description: Makes a callout to the Stripe API to create a customer.
  @return: StripeCustomerWrapper - A wrapper object containing the response from the Stripe API.
  @param: customer: StripeCustomerWrapper.CustomerRequest - The customer request object containing the details of the customer to be created.
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
  @param amount: Decimal - The amount for the price, in the smallest currency unit (e.g., cents).
  @param currencyCode: String - The currency code for the price (e.g., 'usd').
  @param interval: String - The billing interval for the price (e.g., 'month', 'year').
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
    description: Cancels a Stripe subscription.
    @param subscriptionId: String - The ID of the subscription to be canceled.
    @return: SubscriptionsWrapper - A wrapper object containing the response from the Stripe API after cancellation.
  */
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
    description: Creates a Stripe Checkout Session for a given checkout session wrapper.
    @param checkoutSession: CheckoutSessionWrapper - The checkout session object containing the details for the session to be created.
    @return: CheckoutSessionWrapper - A wrapper object containing the response from the Stripe API after creating the checkout session.
  */
  public static CheckoutSessionWrapper createCheckoutSession(
    CheckoutSessionWrapper checkoutSession
  ) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Stripe_NC/checkout/sessions');
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    req.setMethod('POST');
    req.setBody(CheckoutSessionWrapper.toFormBody(checkoutSession));

    // Log the HTTP callout details
    Logger.debug(
      'HTTP Callout to Stripe Checkout Session API: ' +
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
        'Error with HTTP Callout to Checkout Session Endpoint: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
      Logger.saveLog();
      throw new CalloutException(
        'Error with HTTP Callout to Checkout Session Endpoint: ' +
          response.getStatusCode() +
          ' - ' +
          response.getStatus() +
          response.getBody()
      );
    }

    Logger.debug(
      'HTTP Callout successful to Checkout Session Endpoint: ' +
        response.getStatusCode() +
        ' HTTP Callout response to Checkout Session Endpoint: ' +
        response.getBody()
    );
    Logger.saveLog();

    CheckoutSessionWrapper wrapper = CheckoutSessionWrapper.parse(
      response.getBody()
    );
    return wrapper;
  }

  /*
    description: Helper class that converts the customer request to a URL-encoded string
    @return: String - The URL-encoded string representation of the customer request
    @param customerRequest : StripeCustomerWrapper.CustomerRequest - The customer request object containing the details of the customer to be created.
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
