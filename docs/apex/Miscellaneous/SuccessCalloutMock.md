---
layout: default
---

## SuccessCalloutMock class

Inner class for handling mock HTTP callouts.

---

### Methods

#### `respond(HttpRequest request)` → `HttpResponse`

Returns the mock HTTP response.

##### Parameters

| Param     | Description                             |
| --------- | --------------------------------------- |
| `request` | The HTTP request to &quot;receive&quot; |

##### Return

**Type**

HttpResponse

**Description**

The resulting HTTP response

---

### Inner Classes

#### SuccessCalloutMock.FailureCalloutMock class

Inner class for handling mock HTTP callouts that should end in errors / exceptions.

---

##### Methods

###### `respond(HttpRequest request)` → `HttpResponse`

Returns the mock HTTP response.

####### Parameters

| Param     | Description                             |
| --------- | --------------------------------------- |
| `request` | The HTTP request to &quot;receive&quot; |

####### Return

**Type**

HttpResponse

**Description**

The resulting HTTP response

---
