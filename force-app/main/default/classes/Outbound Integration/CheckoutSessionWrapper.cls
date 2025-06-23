public class CheckoutSessionWrapper {
  public String id;
  public String mode;
  public List<LineItem> line_items;
  public String success_url;
  public String cancel_url;
  public String customer;
  public String currency_code;
  public String url;

  public class LineItem {
    public String price;
    public Integer quantity;
  }

  public static CheckoutSessionWrapper parse(String responseBody) {
    {
      CheckoutSessionWrapper wrapper = new CheckoutSessionWrapper();
      wrapper = (CheckoutSessionWrapper) JSON.deserialize(
        responseBody,
        CheckoutSessionWrapper.class
      );
      System.debug('Parsed CheckoutSessionWrapper: ' + wrapper);
      Logger.debug('Parsed CheckoutSessionWrapper: ' + wrapper);
      Logger.saveLog();
      return wrapper;
    }
  }

  public static String toFormBody(CheckoutSessionWrapper session) {
    List<String> parts = new List<String>();
    parts.add('mode=' + EncodingUtil.urlEncode(session.mode, 'UTF-8'));
    System.debug('Parts before URL encoding: ' + parts);
    parts.add(
      'success_url=' + EncodingUtil.urlEncode(session.success_url, 'UTF-8')
    );
    System.debug('Parts after URL encoding: ' + parts);
    parts.add(
      'cancel_url=' + EncodingUtil.urlEncode(session.cancel_url, 'UTF-8')
    );
    System.debug('Parts after cancel_url encoding: ' + parts);
    parts.add('customer=' + EncodingUtil.urlEncode(session.customer, 'UTF-8'));
    System.debug('Parts after customer encoding: ' + parts);
    parts.add(
      'currency=' + EncodingUtil.urlEncode(session.currency_code, 'UTF-8')
    );
    System.debug('Parts after currency encoding: ' + parts);

    for (Integer i = 0; i < session.line_items.size(); i++) {
      parts.add(
        'line_items[' +
          i +
          '][price]=' +
          EncodingUtil.urlEncode(session.line_items[i].price, 'UTF-8')
      );
      parts.add(
        'line_items[' +
          i +
          '][quantity]=' +
          String.valueOf(session.line_items[i].quantity)
      );
    }
    System.debug('Checkout Session Form Body: ' + parts);
    Logger.debug('Form body parts: ' + parts);
    Logger.saveLog();
    return String.join(parts, '&');
  }
}
