public without sharing class Namespace {
    private static String namespacePrefix;

    // public static Boolean hasNamespace() {
    //     return !String.isBlank(getNamespace());
    // }

    public static String getNamespace() {
        if (namespacePrefix == null) {
            String className = Namespace.class.getName();
            namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';
        }

        return namespacePrefix;
    }

    public static String getNamespaceWithDotNotation() {
        return String.isBlank(getNamespace()) ? '' : getNamespace() + '.';
    }
}
