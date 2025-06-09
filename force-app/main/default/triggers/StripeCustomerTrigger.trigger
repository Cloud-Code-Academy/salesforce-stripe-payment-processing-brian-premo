trigger StripeCustomerTrigger on Stripe_Customer__c(
  after insert,
  after update
) {
  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      StripeCustomerTriggerHandler.afterInsert(Trigger.new);
    }
  }
}
