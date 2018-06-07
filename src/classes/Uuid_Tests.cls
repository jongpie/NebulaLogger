/*************************************************************************************************
* This file is part of the Nebula Framework project, released under the MIT License.             *
* See LICENSE file or go to https://github.com/jongpie/NebulaFramework for full license details. *
*************************************************************************************************/
@isTest
private class Uuid_Tests {

    @isTest
    static void it_should_consider_all_zeroes_string_to_be_empty() {
        System.assert(Uuid.isEmpty('00000000-0000-0000-0000-000000000000'));
    }

    @isTest
    static void it_should_create_a_new_Uuid() {
        String generatedUuid = new Uuid().getValue();
        System.assertEquals(36, generatedUuid.length());
    }

    @isTest
    static void it_should_reuse_a_Uuid_on_subsequent_calls_to_getValue() {
        Uuid theUuid = new Uuid();
        String originalValue = theUuid.getValue();

        for(Integer i = 0; i < 5; i++) {
            System.assertEquals(originalValue, theUuid.getValue());
        }
    }

    @isTest
    static void it_should_verify_that_a_Uuid_is_a_Uuid() {
        String generatedUuid = new Uuid().getValue();
        System.assert(Uuid.isValid(generatedUuid));
    }

    @isTest
    static void it_should_consider_null_string_an_empty_Uuid() {
        System.assert(Uuid.isEmpty(null));
    }

    @isTest
    static void it_should_not_consider_an_empty_string_a_Uuid() {
        System.assertEquals(false, Uuid.isValid(''));
    }

    @isTest
    static void it_should_not_consider_null_a_Uuid() {
        System.assertEquals(false, Uuid.isValid(null));
    }

    @isTest
    static void it_should_validate_a_Uuid_in_upper_case() {
        String exampleUuid = 'f3665813-1a60-4924-ad9b-23a9cef17d80'.toUpperCase();
        System.assertEquals(true, Uuid.isValid(exampleUuid));
    }

    @isTest
    static void it_should_validate_a_Uuid_in_lower_case() {
        String exampleUuid = 'f3665813-1a60-4924-ad9b-23a9cef17d80'.toLowerCase();
        System.assertEquals(true, Uuid.isValid(exampleUuid));
    }

}