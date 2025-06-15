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
      Logger.debug('Parsed CheckoutSessionWrapper: ' + wrapper);
      Logger.saveLog();
      return wrapper;
    }
  }

  public static String toFormBody(CheckoutSessionWrapper session) {
    List<String> parts = new List<String>();
    parts.add('mode=' + EncodingUtil.urlEncode(session.mode, 'UTF-8'));
    parts.add(
      'success_url=' + EncodingUtil.urlEncode(session.success_url, 'UTF-8')
    );
    parts.add(
      'cancel_url=' + EncodingUtil.urlEncode(session.cancel_url, 'UTF-8')
    );
    parts.add('customer=' + EncodingUtil.urlEncode(session.customer, 'UTF-8'));
    parts.add(
      'currency=' + EncodingUtil.urlEncode(session.currency_code, 'UTF-8')
    );

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
    Logger.debug('Form body parts: ' + parts);
    Logger.saveLog();
    return String.join(parts, '&');
  }
}
