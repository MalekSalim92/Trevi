public with sharing class FormSubmissionEventTriggerHandler {
    public static void handleAfterInsert(List<Form_Submission_Event__e> events) {

        List<FeedItem> feedItems = new List<FeedItem>();
        
        for(Form_Submission_Event__e event : events) {
            // Deserialize the form data
            Map<String, Object> formData = (Map<String, Object>)JSON.deserializeUntyped(event.formData__c);
            
            // Build chatter post
            String feedMessage = 'Form Submission Details:\n\n';
            
            // List of fields to check
            List<String> fields = new List<String>{
                'isAddressCorrect', 'addressComment', 'isContractCorrect', 'contractComment',
                'spaAreaComment', 'deliveryLocation', 'spaAreaLocation', 'comminicationPreference',
                'accessMeetsRequirements', 'wantToBeContacted', 'phoneNumber', 'remplacementSelection',
                'meubleSelection', 'terrainDroitSelection', 'hlAccessSelection', 'demonteeSelection',
                'installationSelection', 'gazonSelection', 'hlObstacle', 'hlGradeurComment',
                'deniveleComment', 'meubleComment', 'endroitInstallation', 'acComment', 'abComment'
            };
            
            // Map of field keys to labels
            Map<String, String> fieldLabels = new Map<String, String>{
                'isAddressCorrect' => 'Address Confirmation',
                'addressComment' => 'Address Comment',
                'isContractCorrect' => 'Contract Confirmation',
                'contractComment' => 'Contract Comment',
                'spaAreaComment' => 'Spa Area Comment',
                'deliveryLocation' => 'Delivery Location',
                'spaAreaLocation' => 'Spa Area Location',
                'comminicationPreference' => 'Communication Preference',
                'accessMeetsRequirements' => 'Access Requirements Met',
                'wantToBeContacted' => 'Wants to be Contacted',
                'phoneNumber' => 'Phone Number',
                'remplacementSelection' => 'Replacement Selection',
                'meubleSelection' => 'Meuble Selection',
                'terrainDroitSelection' => 'Terrain Droit Selection',
                'deniveleComment' => 'Denivele Comment',
                'hlAccessSelection' => 'HL Access Selection',
                'demonteeSelection' => 'Demontee Selection',
                'installationSelection' => 'Installation Selection',
                'gazonSelection' => 'Gazon Selection',
                'hlObstacle' => 'HL Obstacle',
                'hlGradeurComment' => 'HL Gradeur Comment',
                'meubleComment' => 'Meuble Comment',
                'endroitInstallation' => 'Endroit Installation',
                'acComment' => 'AC Comment',
                'abComment' => 'AB Comment'
            };
            
            for(String field : fields) {
                if(formData.containsKey(field) && formData.get(field) != null) {
                    feedMessage += '• ' + fieldLabels.get(field) + ': ';
                    if(formData.get(field) instanceof Boolean) {
                        feedMessage += ((Boolean)formData.get(field) ? 'Yes' : 'No');
                    } else {
                        feedMessage += String.valueOf(formData.get(field));
                    }
                    feedMessage += '\n';
                }
            }
            
            // Remove trailing newline if present
            if (feedMessage.endsWith('\n')) {
                feedMessage = feedMessage.substring(0, feedMessage.length() - 1);
            }
    
            // Create FeedItem
            FeedItem post = new FeedItem(
                ParentId = event.recordId__c,
                Body = feedMessage,
                Type = 'TextPost'
            );
            
            feedItems.add(post);
        }
        
        if(!feedItems.isEmpty()) {
            insert feedItems;
        }
    }
    }
