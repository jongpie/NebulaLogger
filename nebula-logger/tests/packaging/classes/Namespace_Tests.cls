/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class Namespace_Tests {
    static String getPrefix() {
        String className = Namespace.class.getName();
        return className.contains('.') ? className.substringBefore('.') : '';
    }

    @isTest
    static void it_should_check_if_there_is_a_namespace_prefix() {
        Boolean expectedResult = Namespace_Tests.class.getName().contains('.');

        Test.startTest();
        Boolean actualResult = Namespace.hasPrefix();
        Test.stopTest();

        System.assertEquals(expectedResult, actualResult);
    }

    @isTest
    static void it_should_return_namespace_prefix() {
        String expectPrefix = getPrefix();

        Test.startTest();
        String actualPrefix = Namespace.getPrefix();
        Test.stopTest();

        System.assertEquals(expectPrefix, actualPrefix);
    }

    @isTest
    static void it_should_return_namespace_prefix_with_delimiter() {
        String dotDelimiter = '.';
        String doubleUnderscoreDelimiter = '__';

        String expectPrefixWithDot = String.isBlank(getPrefix()) ? '' : getPrefix() + dotDelimiter;
        String expectPrefixWithDoubleUnderscore = String.isBlank(getPrefix())
            ? ''
            : getPrefix() + doubleUnderscoreDelimiter;

        Test.startTest();
        String actualPrefixWithDot = Namespace.getPrefixWithDelimiter(dotDelimiter);
        String actualPrefixWithDoubleUnderscore = Namespace.getPrefixWithDelimiter(doubleUnderscoreDelimiter);
        Test.stopTest();

        System.assertEquals(expectPrefixWithDot, actualPrefixWithDot);
        System.assertEquals(expectPrefixWithDoubleUnderscore, actualPrefixWithDoubleUnderscore);
    }
}
