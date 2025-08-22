trigger FormSubmissionEventTrigger on Form_Submission_Event__e (after insert) {
    FormSubmissionEventTriggerHandler.handleAfterInsert(Trigger.new);
    }