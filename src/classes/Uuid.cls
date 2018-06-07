/*************************************************************************************************
* This file is part of the Nebula Framework project, released under the MIT License.             *
* See LICENSE file or go to https://github.com/jongpie/NebulaFramework for full license details. *
*************************************************************************************************/
public without sharing class Uuid {

    public static Boolean isEmpty(String uuid) {
        return String.isBlank(uuid) || uuid == '00000000-0000-0000-0000-000000000000';
    }

    public static Boolean isValid(String uuid) {
        if(isEmpty(uuid)) return false;

        String uuidRegEx = '[A-F0-9]{8}(?:-[A-F0-9]{4}){3}-[A-F0-9]{12}';
        Pattern uuidPattern = Pattern.compile(uuidRegEx);
        Matcher uuidMatcher = uuidPattern.matcher(uuid.toUpperCase());

        return uuidMatcher.matches();
    }

    private String value;

    public Uuid() {
        this.setValue();
    }

    public String getValue() {
        return this.value;
    }

    private void setValue() {
        Blob generatedBlob = Crypto.GenerateAESKey(128);
        String hex = EncodingUtil.ConvertTohex(generatedBlob);
        this.value = this.formatValue(hex);
    }

    private String formatValue(String unformattedValue) {
        // Remove any non-alphanumeric characters. Should be unnecessary, but better to be safe than sorry.
        unformattedValue = unformattedValue.replaceAll('[^a-zA-Z0-9]', '');

        String formattedValue = unformattedValue.substring(0, 8)
            + '-' + unformattedValue.substring(8, 12)
            + '-' + unformattedValue.substring(12, 16)
            + '-' + unformattedValue.substring(16, 20)
            + '-' + unformattedValue.substring(20);

        return formattedValue.toUpperCase();
    }

}