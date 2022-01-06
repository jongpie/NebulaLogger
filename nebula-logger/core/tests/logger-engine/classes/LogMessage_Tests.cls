//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogMessage_Tests {
    public class CustomLogMessage extends LogMessage {
        private String inputString;
        public CustomLogMessage(String inputString) {
            this.inputString = inputString;
        }
        public override String getMessage() {
            return inputString;
        }
    }

    @IsTest
    static void it_should_support_extending_LogMessage_class() {
        String expectedMessage = 'The current time is: ' + System.now();

        Test.startTest();

        CustomLogMessage customLogMessage = new CustomLogMessage(expectedMessage);
        String returnedMessage = customLogMessage.getMessage();

        Test.stopTest();

        System.assertEquals(expectedMessage, returnedMessage);
    }

    @IsTest
    static void it_should_return_formatted_message_when_1_object_list_parameter_provided() {
        String unformattedMessage = 'my string with 1 input: {0}';
        List<Object> arguments = new List<Object>{ System.now() };
        String expectedMessage = String.format(unformattedMessage, arguments);

        Test.startTest();
        String returnedMessage = new LogMessage(unformattedMessage, arguments).getMessage();
        Test.stopTest();

        System.assertEquals(expectedMessage, returnedMessage);
    }

    @IsTest
    static void it_should_return_formatted_message_when_1_object_parameter_provided() {
        String unformattedMessage = 'my string with 1 input: {0}';
        Datetime argument1 = System.now();
        String expectedMessage = String.format(unformattedMessage, new List<Object>{ argument1 });

        Test.startTest();
        String returnedMessage = new LogMessage(unformattedMessage, argument1).getMessage();
        Test.stopTest();

        System.assertEquals(expectedMessage, returnedMessage);
    }

    @IsTest
    static void it_should_return_formatted_message_when_2_object_parameters_provided() {
        String unformattedMessage = 'my string with 1 input: {0}';
        Datetime argument1 = System.now();
        Date argument2 = System.today();
        String expectedMessage = String.format(unformattedMessage, new List<Object>{ argument1, argument2 });

        Test.startTest();
        String returnedMessage = new LogMessage(unformattedMessage, argument1, argument2).getMessage();
        Test.stopTest();

        System.assertEquals(expectedMessage, returnedMessage);
    }

    @IsTest
    static void it_should_return_formatted_message_when_3_object_parameters_provided() {
        String unformattedMessage = 'my string with 1 input: {0} and then {1} and finally {2}';
        Datetime argument1 = System.now();
        Date argument2 = System.today();
        User argument3 = new User(Id = UserInfo.getUserId());
        String expectedMessage = String.format(unformattedMessage, new List<Object>{ argument1, argument2, argument3 });

        Test.startTest();
        String returnedMessage = new LogMessage(unformattedMessage, argument1, argument2, argument3).getMessage();
        Test.stopTest();

        System.assertEquals(expectedMessage, returnedMessage);
    }
}
