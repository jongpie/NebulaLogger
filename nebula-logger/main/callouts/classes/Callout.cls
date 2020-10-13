/***********************************************************************************************
* This file is part of the Apex Callouts project, released under the MIT License.              *
* See LICENSE file or go to https://github.com/jongpie/ApexCallouts for full license details.  *
***********************************************************************************************/
public class Callout {

    private String endpoint;
    private Map<String, String> headers;
    private Map<String, String> parameters;
    @testVisible private HttpRequest request;

    public Callout(String namedCredential, String endpointPath) {
        this();

        this.endpoint = 'callout:' + namedCredential + endpointPath;
    }

    public Callout(String endpoint) {
        this();

        this.endpoint = endpoint;
    }

    private Callout() {
        this.headers    = new Map<String, String>();
        this.parameters = new Map<String, String>();
        this.request    = new HttpRequest();
    }

    public Callout setClientCertificateName(String clientCertificateName) {
        this.request.setClientCertificateName(clientCertificateName);
        return this;
    }

    public Callout setCompressed() {
        return this.setCompressed(true);
    }

    public Callout setCompressed(Boolean compress) {
        this.request.setCompressed(compress);
        return this;
    }

    public Callout setHeader(String key, String value) {
        this.setHeaders(new Map<String, String>{key => value});
        return this;
    }

    public Callout setHeaders(Map<String, String> headers) {
        this.headers.putAll(headers);
        return this;
    }

    public Callout setParameter(String key, String value) {
        this.setParameters(new Map<String, String>{key => value});
        return this;
    }

    public Callout setParameters(Map<String, String> parameters) {
        this.parameters.putAll(parameters);
        return this;
    }

    public Callout setTimeout(Integer timeoutMs) {
        this.request.setTimeout(timeoutMs);
        return this;
    }

    public HttpResponse del() {
        // 'DELETE' is a reserved word in Apex, so method name has been abbreviated
        return this.executeCallout('DELETE', null);
    }

    public HttpResponse get() {
        return this.executeCallout('GET', null);
    }

    public HttpResponse head() {
        return this.executeCallout('HEAD', null);
    }

    public HttpResponse patch() {
        return this.patch(null);
    }

    public HttpResponse patch(Object requestBody) {
        return this.executeCallout('PATCH', requestBody);
    }

    public HttpResponse post() {
        return this.post(null);
    }

    public HttpResponse post(Object requestBody) {
        return this.executeCallout('POST', requestBody);
    }

    public HttpResponse put() {
        return this.put(null);
    }

    public HttpResponse put(Object requestBody) {
        return this.executeCallout('PUT', requestBody);
    }

    public HttpResponse trace() {
        return this.executeCallout('TRACE', null);
    }

    private HttpResponse executeCallout(String httpVerb, Object requestBody) {
        this.request.setMethod(httpVerb);
        this.setHeaders();
        this.setEndpointAndParameters();
        this.setRequestBody(requestBody);

        HttpResponse response = new Http().send(this.request);
        this.validateResponse(response);
        return response;
    }

    private void setHeaders() {
        for(String headerKey : this.headers.keySet()) {
            this.request.setHeader(headerKey, this.headers.get(headerKey));
        }
    }

    private void setEndpointAndParameters() {
        String parameterString = '';
        for(String parameterKey : this.parameters.keySet()) {
            String paremeterDelimiter = String.isEmpty(parameterString) && !this.endpoint.contains('?') ? '?' : '&';
            parameterString += paremeterDelimiter + parameterKey + '=' + this.parameters.get(parameterKey);
        }
        this.request.setEndpoint(this.endpoint + parameterString);
    }

    private void setRequestBody(Object requestBody) {
        if(requestBody == null) return;

        // Determine if the content type has already been set
        // If it's null, then it will be automatically set based on the request body
        Boolean contentTypeNotSet = this.headers.get('Content-Type') == null;

        if(requestBody instanceOf Blob) {
            this.request.setBodyAsBlob((Blob)requestBody);
            if(contentTypeNotSet) this.setHeader('Content-Type', 'multipart/form-data; charset=utf-8');
        } else if(requestBody instanceOf Dom.Document) {
            this.request.setBodyDocument((Dom.Document)requestBody);
            if(contentTypeNotSet) this.setHeader('Content-Type', 'text/xml; charset=utf-8');
        } else {
            this.request.setBody(Json.serialize(requestBody));
            if(contentTypeNotSet) this.setHeader('Content-Type', 'application/json; charset=utf-8');
        }
    }

    private void validateResponse(Httpresponse response) {
        Integer statusCode = response.getStatusCode();
        if(statusCode >= 400) {
            // Get the endpoint without any parameters so that no sensitive parameters are exposed to users
            Integer endpointParametersStart = this.endpoint.indexOf('?');
            String endpointWithoutParameters = endpointParametersStart > 0 ? this.endpoint.left(endpointParametersStart) : this.endpoint;

            String errorMessage = 'Callout failed for ' + endpointWithoutParameters + '. Received request status code '
                + statusCode + ', status message: ' + response.getStatus();
            throw new HttpResponseException(errorMessage);
        }
    }

    public class HttpResponseException extends Exception {}

}