public class SubscriptionsWrapper {
  public String customer;
  public String id;
  public ItemWrapper items;
  public String prorationBehavior;
  public String status;

  public class ItemWrapper {
    public String objectType;
    public List<Item> data;
  }

  public class Item {
    public Price price;
    public String current_period_start;
    public String current_period_end;
  }

  public class Price {
    public String id;
  }

  /* description: Converts the SubscriptionsWrapper object to a URL-encoded string for use in an HTTP request body.
   * @return: String - The URL-encoded string representation of the SubscriptionsWrapper object.
   *
   */
  public String toFormCreateSubBody() {
    List<String> parts = new List<String>();
    parts.add('payment_behavior=default_incomplete');
    parts.add('customer=' + EncodingUtil.urlEncode(customer, 'UTF-8'));
    for (Integer i = 0; i < items.data.size(); i++) {
      parts.add(
        'items[' +
          i +
          '][price]=' +
          EncodingUtil.urlEncode(items.data[i].price.id, 'UTF-8')
      );
    }
    Logger.debug('Form body parts: ' + parts);
    Logger.saveLog();
    return String.join(parts, '&');
  }

  public String toFormUpdateSubBody() {
    List<String> parts = new List<String>();
    parts.add(
      'proration_behavior=' + EncodingUtil.urlEncode(prorationBehavior, 'UTF-8')
    );
    for (Integer i = 0; i < items.data.size(); i++) {
      parts.add(
        'items[' +
          i +
          '][price]=' +
          EncodingUtil.urlEncode(items.data[i].price.id, 'UTF-8')
      );
    }
    Logger.debug('Form body parts: ' + parts);
    Logger.saveLog();
    return String.join(parts, '&');
  }

  /* description: Parses the JSON response from the Stripe API and returns a SubscriptionsWrapper object.
   * @param responseBody: String - The JSON response body from the Stripe API.
   * @return: SubscriptionsWrapper - An instance of SubscriptionsWrapper containing the parsed data.
   *
   */
  public static SubscriptionsWrapper parse(String responseBody) {
    SubscriptionsWrapper wrapper = new SubscriptionsWrapper();
    wrapper = (SubscriptionsWrapper) JSON.deserialize(
      responseBody,
      SubscriptionsWrapper.class
    );
    Logger.debug('Parsed SubscriptionsWrapper: ' + wrapper);
    Logger.saveLog();
    return wrapper;
  }

  /*
   * description: Converts a Unix timestamp (in seconds) to a Datetime object.
   * @param unixTimestamp: String - The Unix timestamp to convert.
   * @return: Datetime - The converted Datetime object.
   *
   * Note: The Unix timestamp is expected to be in seconds, while Apex Datetime expects milliseconds.
   */
  public static Datetime convertUnixToDatetime(String unixTimestamp) {
    // Unix timestamp is in seconds, Apex expects milliseconds
    Long longTimestamp = Long.valueOf(unixTimestamp);
    return Datetime.newInstance(1970, 1, 1, 0, 0, 0)
      .addSeconds((Integer) longTimestamp);
  }
}
