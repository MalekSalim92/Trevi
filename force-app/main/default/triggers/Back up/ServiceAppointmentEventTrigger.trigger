trigger ServiceAppointmentEventTrigger on Service_Appointment_Update_Event__e (after insert) {
    ServiceAppointmentEventTriggerHandler.handleServiceUpdateEvent(Trigger.new);
}