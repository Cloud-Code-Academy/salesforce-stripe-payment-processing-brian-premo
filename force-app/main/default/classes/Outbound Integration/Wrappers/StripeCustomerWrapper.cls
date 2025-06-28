/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Wrapper class for handling Stripe API responses.
 *
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-05
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-05-05 v1.0.0 Initial creation
 * -----------------------------------------------------------------------------
 */
public with sharing class StripeCustomerWrapper {
  public String id;
  public class CustomerRequest {
    public String name;
    public String email;
    public String phone;
    public InvoiceSettings invoice_settings;
  }

  public class InvoiceSettings {
    public String default_payment_method;
  }

  /* description: Parses the JSON response from the Stripe API and returns a StripeCustomerWrapper object.
   * @param responseBody: String - The JSON response body from the Stripe API.
   * @return: StripeCustomerWrapper - An instance of StripeCustomerWrapper containing the parsed data.
   *
   */
  public static StripeCustomerWrapper parse(String responseBody) {
    // Use JSON.deserialize or JSON.deserializeStrict to parse the response
    StripeCustomerWrapper wrapper = new StripeCustomerWrapper();
    wrapper = (StripeCustomerWrapper) JSON.deserialize(
      responseBody,
      StripeCustomerWrapper.class
    );
    return wrapper;
  }
}
