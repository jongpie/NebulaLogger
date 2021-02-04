/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
public without sharing class Namespace {
    private static String namespacePrefix;

    public static Boolean hasPrefix() {
        return !String.isBlank(getPrefix());
    }

    public static String getPrefix() {
        if (namespacePrefix == null) {
            String className = Namespace.class.getName();
            namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';
        }

        return namespacePrefix;
    }

    public static String getPrefixWithDelimiter(String delimiter) {
        return String.isBlank(getPrefix()) ? '' : getPrefix() + delimiter;
    }
}
