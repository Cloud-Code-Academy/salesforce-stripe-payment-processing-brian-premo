/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Interface for webhook processors
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
/*
 * @description Interface for webhook processors
 * All webhook processors should implement this interface
 */
public interface IWebhookProcessor {
  /**
   * @description Validates the incoming webhook request
   * @param request The REST request containing the webhook payload
   * @return Boolean True if the request is valid, false otherwise
   */
  Boolean validate(RestRequest request);

  /**
   * @description Processes the webhook request
   * @param request The REST request containing the webhook payload
   */
  void process(RestRequest request);
}
