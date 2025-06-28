trigger StripeSubscriptionTrigger on Stripe_Subscription__c(
  after insert,
  after update
) {
  if (Trigger.isAfter) {
    if (Trigger.isInsert) {
      StripeSubscriptionTriggerHandler.afterInsert(Trigger.new);
    } else if (Trigger.isUpdate) {
      StripeSubscriptionTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
  }
}
