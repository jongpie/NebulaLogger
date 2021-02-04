public without sharing class Namespace {
    private static String namespacePrefix;

    public static Boolean hasNamespace() {
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
