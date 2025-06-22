/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Webhook Resource for handling incoming webhooks
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

@RestResource(urlMapping='/integration/*')
global without sharing class WebhookResource {
  /**
   * @description Handles incoming webhook requests
   * This method is called when a POST request is made to the /webhook endpoint
   * It processes the webhook based on the path and request body
   */
  @HttpPost
  global static ResponseWrapper doPost() {
    RestRequest req = RestContext.request;
    System.debug('Received webhook: ' + req);
    RestResponse res = RestContext.response;
    String path = WebhookResource.getWebhookTypeFromPath(req.requestURI);
    System.debug('Processing webhook for path: ' + path);
    try {
      WebhookFactory.processWebhook(path, req);
      res.statusCode = 200;
      return new ResponseWrapper('success', 'Webhook processed successfully');
    } catch (Exception e) {
      res.statusCode = 500;
      return new ResponseWrapper(
        'error',
        'Error processing webhook: ' + e.getMessage()
      );
    }
  }

  global class ResponseWrapper {
    public String status;
    public String message;

    public ResponseWrapper(String status, String message) {
      this.status = status;
      this.message = message;
    }
  }

  private static String getWebhookTypeFromPath(String path) {
    System.debug('Webhook path: ' + path);
    if (path == null) {
      return '';
    }

    Integer integrationIndex = path.indexOf('/integration/');
    if (integrationindex >= 0) {
      String remaining = path.substring(
        integrationIndex + '/integration/'.length()
      );
      Integer nextSlashIndex = remaining.indexOf('/');
      if (nextSlashIndex > 0) {
        return remaining.substring(0, nextSlashIndex);
      }
      return remaining;
    }
    return '';
  }
}
