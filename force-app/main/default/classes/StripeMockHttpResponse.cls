/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Mock HTTP response class for testing Stripe API callouts in Apex.
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-12
 * LAST EDITED :
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-12 v1.0.0 Initial creation
 *  - 2025-06-14 v1.0.1 Added more mock responses for various Stripe API endpoints
 * -----------------------------------------------------------------------------
 */
@isTest
public class StripeMockHttpResponse implements HttpCalloutMock {
  public Integer statusCode;
  public String status;
  public String body;

  public StripeMockHttpResponse(
    Integer statusCode,
    String status,
    String body
  ) {
    this.statusCode = statusCode;
    this.status = status;
    this.body = body;
  }

  public HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setStatusCode(statusCode);
    res.setStatus(status);
    res.setBody(body);

    return res;
  }

  // Helper methods to create common mock responses
  public static StripeMockHttpResponse createSuccessCustomerResponse() {
    String body = '{"id":"cus_123456","object":"customer","address":null,"balance":0,"created":1749500297,"currency":null,"default_source":null,"delinquent":false,"description":null,"discount":null,"email":"test@example.com","invoice_prefix":"MVNZQEQO","invoice_settings":{"custom_fields":null,"default_payment_method":null,"footer":null,"rendering_options":null},"livemode":false,"metadata":{},"name":"Test Customer","next_invoice_sequence":1,"phone":"1234567890","preferred_locales":[],"shipping":null,"tax_exempt":"none","test_clock":null}';
    return new StripeMockHttpResponse(200, 'OK', body);
  }

  public static StripeMockHttpResponse createErrorCustomerResponse() {
    String body = '{"error":{"code":"invalid_email","doc_url":"https://stripe.com/docs/error-codes/invalid-email","message":"The email address provided is invalid.","param":"email","type":"invalid_request_error"}';

    return new StripeMockHttpResponse(400, 'Bad Request', body);
  }

  public static StripeMockHttpResponse createSuccessSubscriptionCreationResponse() {
    String body = '{"id":"sub_123456","object":"subscription","customer":"cus_123456","status":"active","items":{"object":"list","data":[{"id":"si_123456","object":"subscription_item","price":{"id":"price_123456"},"current_period_start":"1749501619","current_period_end":"1752093619"}]}}';
    return new StripeMockHttpResponse(200, 'OK', body);
  }

  public static StripeMockHttpResponse createErrorSubscriptionCreationResponse() {
    String body = '{"error":{"message":"No such price: price_123456","param":"items[0][price]","request_log_url":"https://dashboard.stripe.com/test/logs/req_EFAwx0m1orrVkb?t=1749501619","type":"invalid_request_error"}}';
    return new StripeMockHttpResponse(400, 'Bad Request', body);
  }

  public static StripeMockHttpResponse createSuccessSubscriptionUpdateResponse() {
    String body = '{"id":"sub_12345","object":"subscription","application":null,"application_fee_percent":null,"automatic_tax":{"disabled_reason":null,"enabled":false,"liability":null},"billing_cycle_anchor":1749767281,"billing_cycle_anchor_config":null,"billing_thresholds":null,"cancel_at":null,"cancel_at_period_end":false,"canceled_at":null,"cancellation_details":{"comment":null,"feedback":null,"reason":null},"collection_method":"charge_automatically","created":1749767281,"currency":"usd","customer":"cus_SUHdEVbHHF9LSn","days_until_due":null,"default_payment_method":null,"default_source":null,"default_tax_rates":[],"description":null,"discounts":[],"ended_at":null,"invoice_settings":{"account_tax_ids":null,"issuer":{"type":"self"}},"items":{"object":"list","data":[{"id":"si_SUIBSofDuZQRlj","object":"subscription_item","billing_thresholds":null,"created":1749767282,"current_period_end":1752359281,"current_period_start":1749767281,"discounts":[],"metadata":{},"plan":{"id":"price_12345","object":"plan","active":true,"amount":3300,"amount_decimal":"3300","billing_scheme":"per_unit","created":1749767281,"currency":"usd","interval":"month","interval_count":1,"livemode":false,"metadata":{},"meter":null,"nickname":null,"product":"prod_SUIBU3zTjYLB93","tiers_mode":null,"transform_usage":null,"trial_period_days":null,"usage_type":"licensed"},"price":{"id":"price_1RZJbJPuoWtmWWxE10Jr7rGN","object":"price","active":true,"billing_scheme":"per_unit","created":1749767281,"currency":"usd","custom_unit_amount":null,"livemode":false,"lookup_key":null,"metadata":{},"nickname":null,"product":"prod_SUIBU3zTjYLB93","recurring":{"interval":"month","interval_count":1,"meter":null,"trial_period_days":null,"usage_type":"licensed"},"tax_behavior":"unspecified","tiers_mode":null,"transform_quantity":null,"type":"recurring","unit_amount":3300,"unit_amount_decimal":"3300"},"quantity":1,"subscription":"sub_1RZJbJPuoWtmWWxEU35wK0A4","tax_rates":[]},{"id":"si_SUIYg1OjLrjAa1","object":"subscription_item","billing_thresholds":null,"created":1749768634,"current_period_end":1752359281,"current_period_start":1749767281,"discounts":[],"metadata":{},"plan":{"id":"price_1RXvNiPuoWtmWWxEou7n40Uq","object":"plan","active":true,"amount":4400,"amount_decimal":"4400","billing_scheme":"per_unit","created":1749435854,"currency":"usd","interval":"month","interval_count":1,"livemode":false,"metadata":{},"meter":null,"nickname":null,"product":"prod_SSr57mykQSDiZo","tiers_mode":null,"transform_usage":null,"trial_period_days":null,"usage_type":"licensed"},"price":{"id":"price_1RXvNiPuoWtmWWxEou7n40Uq","object":"price","active":true,"billing_scheme":"per_unit","created":1749435854,"currency":"usd","custom_unit_amount":null,"livemode":false,"lookup_key":null,"metadata":{},"nickname":null,"product":"prod_SSr57mykQSDiZo","recurring":{"interval":"month","interval_count":1,"meter":null,"trial_period_days":null,"usage_type":"licensed"},"tax_behavior":"unspecified","tiers_mode":null,"transform_quantity":null,"type":"recurring","unit_amount":4400,"unit_amount_decimal":"4400"},"quantity":1,"subscription":"sub_1RZJbJPuoWtmWWxEU35wK0A4","tax_rates":[]}],"has_more":false,"total_count":2,"url":"/v1/subscription_items?subscription=sub_1RZJbJPuoWtmWWxEU35wK0A4"},"latest_invoice":"in_1RZJx8PuoWtmWWxEYG8jwyxd","livemode":false,"metadata":{},"next_pending_invoice_item_invoice":null,"on_behalf_of":null,"pause_collection":null,"payment_settings":{"payment_method_options":null,"payment_method_types":null,"save_default_payment_method":"off"},"pending_invoice_item_interval":null,"pending_setup_intent":null,"pending_update":null,"plan":null,"quantity":null,"schedule":null,"start_date":1749767281,"status":"active","test_clock":null,"transfer_data":null,"trial_end":null,"trial_settings":{"end_behavior":{"missing_payment_method":"create_invoice"}},"trial_start":null}';
    return new StripeMockHttpResponse(200, 'OK', body);
  }

  public static StripeMockHttpResponse createErrorSubscriptionUpdateResponse() {
    String body = '{"error":{"code":"parameter_invalid_enum","doc_url":"https://stripe.com/docs/error-codes/parameter-invalid-enum","message":"Invalid enum value: notarealbehavior. Allowed values are create_prorations, none, or always_invoice.","param":"proration_behavior","type":"invalid_request_error"}}';
    return new StripeMockHttpResponse(400, 'Bad Request', body);
  }

  public static StripeMockHttpResponse createSuccessCancelSubscriptionResponse() {
    String body = '{"id":"sub_123456","object":"subscription","cancel_at_period_end":false,"canceled_at":1749501061,"customer":"cus_ST8PC2IDsNNBrt","status":"canceled"}';
    return new StripeMockHttpResponse(200, 'OK', body);
  }

  public static StripeMockHttpResponse createErrorCancelSubscriptionResponse() {
    String body = '{"error":{"code":"subscription_not_found","doc_url":"https://stripe.com/docs/error-codes/subscription-not-found","message":"The subscription was not found.","param":"subscription","type":"invalid_request_error"}}';
    return new StripeMockHttpResponse(404, 'Not Found', body);
  }

  public static StripeMockHttpResponse createCheckoutSessionSuccessResponse() {
    String body = '{"id":"cs_test_1234567890","object":"checkout.session","amount_total":3300,"currency":"usd","customer":"cus_123456","payment_status":"paid","status":"complete","url":"https://checkout.stripe.com/pay/cs_test_1234567890"}';
    return new StripeMockHttpResponse(200, 'OK', body);
  }
  public static StripeMockHttpResponse createCheckoutSessionErrorResponse() {
    String body = '{"error":{"code":"checkout_session_not_found","doc_url":"https://stripe.com/docs/error-codes/checkout-session-not-found","message":"The checkout session was not found.","param":"session","type":"invalid_request_error"}}';
    return new StripeMockHttpResponse(404, 'Not Found', body);
  }

  public static StripeMockHttpResponse createPriceSuccessResponse() {
    String body = '{"id":"price_12345","object":"price","active":true,"billing_scheme":"per_unit","created":1749767281,"currency":"usd","custom_unit_amount":null,"livemode":false,"lookup_key":null,"metadata":{},"nickname":null,"product":"prod_12345","recurring":{"interval":"month","interval_count":1,"usage_type":"licensed"},"tax_behavior":"unspecified","tiers_mode":null,"transform_quantity":null,"type":"recurring","unit_amount":3300,"unit_amount_decimal":"3300"}';
    return new StripeMockHttpResponse(200, 'OK', body);
  }

  public static StripeMockHttpResponse createPriceErrorResponse() {
    String body = '{"error":{"code":"price_not_found","doc_url":"https://stripe.com/docs/error-codes/price-not-found","message":"The price was not found.","param":"price","type":"invalid_request_error"}}';
    return new StripeMockHttpResponse(404, 'Not Found', body);
  }
}
