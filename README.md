# Salesforce Stripe Payment Processing

## This repository provides a robust Salesforce (Apex) integration with Stripe(https://stripe.com/) for payment processing. It supports both inbound (webhook) and outbound (API callout) Stripe events, enabling seamless synchronization of customers, subscriptions, and payments between Salesforce and Stripe. For data flow diagrams view here (https://miro.com/app/board/uXjVLRyp2JE=/)

## Features

- **Inbound Webhook Handling:**  
  Receives and processes Stripe webhook events (e.g., customer updates, subscription changes, invoice payments) via a REST resource.
- **Outbound Stripe API Integration:**  
  Creates and updates Stripe customers, products, prices, and checkout sessions from Salesforce using HTTP callouts.
- **Custom Metadata for Secrets:**  
  Securely stores Stripe API keys in Salesforce custom metadata.
- **Asynchronous Processing:**  
  Uses Queueable Apex for non-blocking, scalable Stripe API interactions.
- **Comprehensive Unit Tests:**  
  Includes test data factories and HTTP callout mocks for reliable, isolated testing.

---

## Architecture Overview

### Inbound Integration

- **WebhookResource:**  
  Salesforce REST resource endpoint for Stripe webhooks.
- **WebhookFactory:**  
  Routes incoming events to the correct processor based on event type.
- **StripeWebhookProcessor:**  
  Handles business logic for each supported Stripe event (e.g., customer.updated, invoice.paid).

### Outbound Integration

- **StripeAPIClient:**  
  Handles HTTP callouts to Stripe for creating/updating customers, products, prices, and checkout sessions.
- **Queueable Classes:**  
  Asynchronous jobs for creating/updating Stripe objects and syncing results to Salesforce.
- **Wrappers:**  
  Classes for structuring outbound requests and parsing Stripe responses.

### Testing

- **Test Data Factory:**  
  Generates test data and sample webhook payloads.
- **Mock Responses:**  
  Simulates Stripe API responses for unit testing.
- **Test Classes:**  
  Cover both inbound and outbound logic, including signature validation and error handling.

---

## Setup & Configuration

1. **Clone the Repository:**  
   Download or clone this repo into your Salesforce DX project or VS Code workspace.

2. **Deploy Metadata:**  
   Deploy Apex classes, triggers, and custom metadata to your Salesforce org.

3. **Configure Stripe Secret Key:**

   - Go to **Setup > Custom Metadata Types > API_Key_Vault**.
   - Create a record with:
     - **MasterLabel:** Stripe
     - **DeveloperName:** Stripe
     - **Secret_Key\_\_c:** (your Stripe webhook signing secret)

4. **Add Authorization Token to Named Credential:**

   - Go to **Setup > External Credentials**
   - Update the Stripe Principal's Authorization Parameter to contain your Bearer Token

5. **Set Up Remote Site Settings:**

   - Add `https://api.stripe.com` to Remote Site Settings for outbound callouts.

6. **Configure Stripe Webhooks:**
   - In your Stripe dashboard, set the webhook endpoint to your Salesforce REST resource URL (e.g., `https://yourdomain.my.salesforce.com/services/apexrest/integration/stripe`). You will have to create an Experience Page to use as your resource

---

## Usage

- **Inbound:**  
  Stripe sends webhook events to your Salesforce endpoint. The system validates the signature, processes the event, and updates Salesforce records accordingly.

- **Outbound:**  
  When a customer or subscription is created/updated in Salesforce, the system makes HTTP callouts to Stripe to sync the data.

---

## Testing

- Run all test classes in Salesforce to verify functionality.
- Tests use mock HTTP responses and test data factories for isolation and reliability.

---

## Extending

- **Add Retry Logic:**
  - Automatically retry webhook events when they fail
  - Store failed webhooks in a custom object
  - Use Scheduled/Batch Apex to periodically retry failed webhooks
- **Products and Price Custom Object:**
  - Instead of creating new Products and Prices from the Subscription, try
    implementing a Stripe Product Object and Price Object to more closely align
    with Stripe's Data model.
- **Bulkification and Performance**
  - Ensure all DML and SOQL operations are Bulk Safe
  - Add tests for bulk outgoing API calls and inbound webhook event processing
- **Improved Error Handling and Logging**
  - Build off the existing Error logging framework. Add more custom Exceptions
    and ensure logs for important steps
- **Notifications**
  - Send Email or Slack message to admins on repeated failures or critical errors
- **Advanced Features**
  - Support for additional Stripe events like disputes and refunds
  - Implement Idempotency for webhook processing to prevent duplicates

---

## Contributing

1. Fork the repo and create a feature branch.
2. Add or update tests for your changes.
3. Submit a pull request with a clear description.

---

## Contact

For questions or support, contact brianpremo97@gmail.com or open an issue.
