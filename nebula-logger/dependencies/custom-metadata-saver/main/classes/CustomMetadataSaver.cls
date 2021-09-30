//----------------------------------------------------------------------------------------------------//
// This file is part of the Custom Metadata Saver project, released under the MIT License.            //
// See LICENSE file or go to https://github.com/jongpie/CustomMetadataSaver for full license details. //
//----------------------------------------------------------------------------------------------------//

public inherited sharing class CustomMetadataSaver {
    private static final Boolean DEFAULT_SEND_EMAIL_ON_ERROR = false;
    private static final Boolean DEFAULT_SEND_EMAIL_ON_SUCCESS = false;
    private static final List<String> DEPLOYMENT_JOB_IDS = new List<String>();
    private static final Set<String> IGNORED_FIELD_NAMES = getIgnoredFieldNames();
    @testVisible
    private static final String MOCK_DEPLOYMENT_ID = 'fakeDeploymentId';

    public class FlowInput {
        @InvocableVariable(required=true label='Custom Metadata Type Records to Deploy')
        public List<SObject> customMetadataRecords;

        @InvocableVariable(
            required=true
            label='Send Email Alert if the Deployment Fails'
            description='This option is only used by the default callback Apex class.'
        )
        public Boolean sendEmailOnError;

        @InvocableVariable(
            required=true
            label='Send Email Alert if the Deployment Succeeds'
            description='This option is only used by the default callback Apex class.'
        )
        public Boolean sendEmailOnSuccess;

        @InvocableVariable(
            required=false
            label='(Optional) Custom Callback Apex Class'
            description='The name of your Apex class to execute after the deployment completes. When provided, this is used instead of the default callback.'
        )
        public String customCallbackName;
    }

    private CustomMetadataSaver() {
        //static only
    }

    @InvocableMethod(
        category='Custom Metadata'
        label='Deploy Custom Metadata Type Records'
        description='Deploys changes to the list of custom metadata records'
    )
    public static List<String> deploy(List<FlowInput> inputs) {
        System.debug('inputs==' + inputs);

        Boolean sendEmailOnError = DEFAULT_SEND_EMAIL_ON_ERROR;
        Boolean sendEmailOnSuccess = DEFAULT_SEND_EMAIL_ON_SUCCESS;
        String customCallbackName;

        // Combine all CMDT records into 1 list so that there is only 1 deployment
        // TODO allow this to be controlled via FlowInput - there are uses cases for also having multiple deployments
        List<SObject> consolidatedCustomMetadataRecords = new List<SObject>();
        for (FlowInput input : inputs) {
            consolidatedCustomMetadataRecords.addAll(input.customMetadataRecords);
            // If any of the inputs confirm that an email should be sent, then send it - otherwise, no email will be sent
            if (input.sendEmailOnError == true) {
                sendEmailOnError = input.sendEmailOnError;
            }
            // If any of the inputs confirm that an email should be sent, then send it - otherwise, no email will be sent
            if (input.sendEmailOnSuccess == true) {
                sendEmailOnSuccess = input.sendEmailOnSuccess;
            }
            // Assumption: only a single custom callback will be specified
            // If we find a custom callback class name, update the variable
            if (String.isNotBlank(input.customCallbackName)) {
                customCallbackName = input.customCallbackName;
            }
        }

        System.debug('consolidatedCustomMetadataRecords==' + consolidatedCustomMetadataRecords);

        Metadata.DeployCallback callback = getFlowDeployCallback(customCallbackName, sendEmailOnError, sendEmailOnSuccess);
        System.debug('callback==' + callback);

        // TODO need to add an actual Flow to the repo (./extra-tests/ directory probably) to verify Flow functionality works
        String jobId = deploy(consolidatedCustomMetadataRecords, callback);
        List<String> flowJobIds = new List<String>();
        for (Integer i = 0; i < inputs.size(); i++) {
            flowJobIds.add(jobId);
        }
        return flowJobIds;
    }

    public static String deploy(List<SObject> customMetadataRecords) {
        return deploy(customMetadataRecords, new DefaultDeployCallback());
    }

    public static String deploy(List<SObject> customMetadataRecords, Metadata.DeployCallback callback) {
        Metadata.DeployContainer deployment = new Metadata.DeployContainer();

        for (SObject customMetadataRecord : customMetadataRecords) {
            Metadata.CustomMetadata customMetadata = createDeployableCustomMetadata(customMetadataRecord);
            deployment.addMetadata(customMetadata);
        }

        String jobId = Test.isRunningTest() ? MOCK_DEPLOYMENT_ID : Metadata.Operations.enqueueDeployment(deployment, callback);
        DEPLOYMENT_JOB_IDS.add(jobId);
        System.debug(LoggingLevel.INFO, 'Deployment Job ID: ' + jobId);

        return jobId;
    }

    public static List<String> getDeploymentJobIds() {
        return DEPLOYMENT_JOB_IDS;
    }

    private static Set<String> getIgnoredFieldNames() {
        return new Set<String>{ 'DeveloperName', 'Id', 'Label', 'Language', 'MasterLabel', 'NamespacePrefix', 'QualifiedApiName' };
    }

    private static Metadata.CustomMetadata createDeployableCustomMetadata(SObject customMetadataRecord) {
        String customMetadataTypePrefix = customMetadataRecord.getSObjectType().getDescribe().getName().replace('__mdt', '');

        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = customMetadataTypePrefix + '.' + customMetadataRecord.get('DeveloperName');
        customMetadata.label = (String) customMetadataRecord.get('MasterLabel');

        for (String fieldName : customMetadataRecord.getPopulatedFieldsAsMap().keySet()) {
            if (IGNORED_FIELD_NAMES.contains(fieldName)) {
                continue;
            }

            Schema.SObjectField field = customMetadataRecord.getSObjectType().getDescribe().fields.getMap().get(fieldName);

            Object value;
            // Picklist values have to be cast to strings (even though they already look like strings)
            if (field.getDescribe().getType() == Schema.DisplayType.PICKLIST) {
                value = String.valueOf(customMetadataRecord.get(field));
            } else {
                value = customMetadataRecord.get(fieldName);
            }

            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = fieldName;
            customField.value = value;
            System.debug(LoggingLevel.INFO, 'customField==' + customField);

            customMetadata.values.add(customField);
        }

        System.debug(LoggingLevel.INFO, 'customMetadata==' + customMetadata);

        return customMetadata;
    }

    private static Metadata.DeployCallback getFlowDeployCallback(String customCallbackName, Boolean sendEmailOnError, Boolean sendEmailOnSuccess) {
        Metadata.DeployCallback callback;
        if (String.isNotBlank(customCallbackName) && Type.forName(customCallbackName) != null) {
            // Dynamically create a new instance of the specified class
            // Assumption: specified class uses a parameterless constructor
            System.debug('customCallbackName==' + customCallbackName);
            callback = (Metadata.DeployCallback) Type.forName(customCallbackName).newInstance();
        } else {
            // If no custom callback class is specified, use the default inner class
            callback = new DefaultDeployCallback(sendEmailOnError, sendEmailOnSuccess);
        }
        return callback;
    }

    private static void sendEmail(String subject, String textBody) {
        Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
        singleEmail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
        singleEmail.setSubject(subject);
        singleEmail.setPlainTextBody(textBody);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ singleEmail });
    }

    // Inner class used as the default callback if no other callback is specified
    @testVisible
    private class DefaultDeployCallback implements Metadata.DeployCallback {
        @testVisible
        private Boolean success;

        private Boolean sendEmailOnError;
        private Boolean sendEmailOnSuccess;

        @testVisible
        private DefaultDeployCallback() {
            this(DEFAULT_SEND_EMAIL_ON_ERROR, DEFAULT_SEND_EMAIL_ON_SUCCESS);
        }
        @testVisible
        private DefaultDeployCallback(Boolean sendEmailOnError, Boolean sendEmailOnSuccess) {
            this.sendEmailOnError = sendEmailOnError;
            this.sendEmailOnSuccess = sendEmailOnSuccess;
        }

        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            System.debug('deploy result.success==' + result.success);
            System.debug('deploy result==' + result);
            System.debug('deploy callback context==' + context);

            System.debug('this.sendEmailOnError==' + this.sendEmailOnError);
            System.debug('this.sendEmailOnSuccess==' + this.sendEmailOnSuccess);

            this.success = result.success;

            // Build the email pieces
            String subject = 'Custom metadata type deployment completed';
            String textBody = 'Deployment ID {0} completed\nStatus: {1}\n{2} total items deployed\n{3} items failed\nDetails: {4}';
            List<Object> textReplacements = new List<Object>{
                result.id,
                result.status,
                result.numberComponentsTotal,
                result.numberComponentErrors,
                Json.serializePretty(result.details)
            };
            textBody = String.format(textBody, textReplacements);

            // Send the email
            if (result.success == true && this.sendEmailOnSuccess == true) {
                System.debug('Deployment Succeeded!');

                sendEmail(subject, textBody);
            } else if (result.success == false && this.sendEmailOnError == true) {
                System.debug('Deployment Failed!');

                sendEmail(subject, textBody);
            }
        }
    }
}
