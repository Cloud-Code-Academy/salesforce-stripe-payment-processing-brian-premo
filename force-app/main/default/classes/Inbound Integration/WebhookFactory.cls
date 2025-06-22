/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Factory class to process different types of webhooks
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

public with sharing class WebhookFactory {
  /**
   * @description Process a webhook based on its type
   * @param webhookType The type of webhook (e.g., "jira")
   * @param request The REST request containing the webhook payload
   */
  public static void processWebhook(String webhookType, RestRequest request) {
    // Get the appropriate webhook processor
    IWebhookProcessor processor = getProcessor(webhookType);

    if (processor == null) {
      throw new WebhookException('Unsupported webhook type: ' + webhookType);
    }

    // Validate and process the webhook
    if (processor.validate(request)) {
      processor.process(request);
    } else {
      throw new WebhookException(
        'Webhook validation failed for type: ' + webhookType
      );
    }
  }

  /**
   * @description Get the appropriate webhook processor based on the webhook type
   * @param webhookType The type of webhook (e.g., "stripe")
   * @return IWebhookProcessor The appropriate webhook processor
   */
  private static IWebhookProcessor getProcessor(String webhookType) {
    // Return the appropriate processor based on webhook type
    switch on webhookType {
      when 'stripe' {
        return new StripeWebhookProcessor();
      }
      when else {
        return null;
      }
    }
  }

  /**
   * @description Custom exception for webhook processing errors
   */
  public class WebhookException extends Exception {
  }
}
