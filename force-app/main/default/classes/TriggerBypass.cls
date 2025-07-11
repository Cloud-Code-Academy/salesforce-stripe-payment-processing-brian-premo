/**
 * -----------------------------------------------------------------------------
 * DESCRIPTION : Utility class to bypass triggers for specific operations
 * AUTHOR      : Brian Premo
 * CREATED     : 2025-06-12
 * LAST EDITED :
 *
 * VERSION     : 1.0.0
 *
 * CHANGE LOG  :
 *  - 2025-06-12 v1.0.0 Initial creation
 *  - 2025-06-12 v1.0.1 Added customer bypass flag
 * -----------------------------------------------------------------------------
 */
public with sharing class TriggerBypass {
  public static Boolean bypassStripeSubscription = false;
  public static Boolean bypassStripeCustomer = false;
  public static Boolean bypassHMACVerification = false;
}
