trigger UserRegistrationTrigger on User_Registration_Event__e (after insert) {
    UserRegistrationTriggerHandler.handleAfterInsert(Trigger.new);
}