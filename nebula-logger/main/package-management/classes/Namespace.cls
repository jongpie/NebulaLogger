public without sharing class Namespace {
    private static String namespacePrefix;

    // public static Boolean hasNamespace() {
    //     return !String.isBlank(getNamespace());
    // }

    public static String getPrefix() {
        if (namespacePrefix == null) {
            String className = Namespace.class.getName();
            namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';
        }

        return namespacePrefix;
    }

    public static String getPrefixWithDotNotation() {
        return String.isBlank(getPrefix()) ? '' : getPrefix() + '.';
    }
}
