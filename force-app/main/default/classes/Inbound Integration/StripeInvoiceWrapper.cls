/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Wrapper for Stripe Invoice Webhook payload
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
public class StripeInvoiceWrapper {
  public String id;
  public String created;
  public DataWrapper data;

  public class DataWrapper {
    public ObjectWrapper object_wrapper;
  }

  public class ObjectWrapper {
    public String id;
    public LineItem lines;
    public String customer;
    public string invoice_pdf;
    public String created;
    public String currency_code;
    public Integer amount_paid;
    public String status;
  }

  public class LineItem {
    public List<LineItemData> data;
  }

  public class LineItemData {
    public Integer amount;
    public ParentWrapper parent;
  }

  public class ParentWrapper {
    public SubscriptionItemDetailsWrapper subscription_item_details;
  }

  public class SubscriptionItemDetailsWrapper {
    public String subscription;
  }

  public static StripeInvoiceWrapper parse(String jsonBody) {
    // Replace 'object' keys with 'object_wrapper' to avoid reserved keyword issues
    jsonBody = jsonBody.replaceAll('"object":', '"object_wrapper":');
    jsonbody = jsonBody.replaceAll('"currency":', '"currency_code":');
    StripeInvoiceWrapper parsedResponse = (StripeInvoiceWrapper) JSON.deserialize(
      jsonBody,
      StripeInvoiceWrapper.class
    );

    System.debug('Parsed StripeInvoiceWrapper: ' + parsedResponse);
    return parsedResponse;
  }
}
