/**
 * @description  LWC Banner component for displaying a text message in a styled box.
 * @file        serviceAppointmentFormBanner.js
 * @author      Malek
 * @date        2025-04-19
 */

import { LightningElement, api } from 'lwc';

export default class ServiceAppointmentFormBanner extends LightningElement {
    /**
     * @description Public property to display text inside the banner.
     * Defaults to "Example" if no value is provided.
     */
    @api text = 'Example';
}