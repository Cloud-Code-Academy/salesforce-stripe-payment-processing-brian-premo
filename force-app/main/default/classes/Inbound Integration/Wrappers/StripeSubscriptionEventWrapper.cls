/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Wrapper for Stripe Subscription Webhook payload
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
public without sharing class StripeSubscriptionEventWrapper {
  public String id;
  public DataWrapper data;
  public String type;

  public class DataWrapper {
    public ObjectWrapper object_wrapper;
  }

  public class ObjectWrapper {
    public String id;
    public String status;
    public String default_payment_method;
    public ItemsWrapper items;
  }

  public class ItemsWrapper {
    //public String object_type; //object is a reserved keyword in Apex
    public List<SubscriptionItem> data;
  }

  public class SubscriptionItem {
    public Integer quantity;
    public Long current_period_start;
    public Long current_period_end;
    public PriceWrapper price;
  }

  public class PriceWrapper {
    public String id;
    public String object_type; //object is a reserved keyword in Apex
    public Integer unit_amount;
  }

  public static StripeSubscriptionEventWrapper parse(String jsonBody) {
    //Replace 'object' keys with 'object_wrapper' to avoid reserved keyword issues
    jsonBody = jsonBody.replaceAll('"object":', '"object_wrapper":');
    StripeSubscriptionEventWrapper parsedResponse = (StripeSubscriptionEventWrapper) JSON.deserialize(
      jsonBody,
      StripeSubscriptionEventWrapper.class
    );

    return parsedResponse;
  }
}
