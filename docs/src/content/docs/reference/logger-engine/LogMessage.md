---
title: LogMessage
description: 'Nebula Logger class reference: LogMessage.'
---

# LogMessage Class

`virtual`

`SUPPRESSWARNINGS`

Provides the ability to generate string messages on demand, using String.format()

**Group** Logger Engine

**See** [Logger](Logger.md)

**See** [LogEntryEventBuilder](LogEntryEventBuilder.md)

## Constructors

### `LogMessage(unformattedMessage, messageInput)`

Constructor to handle dynamically formatting a string with 1 input

#### Signature

```apex
global LogMessage(String unformattedMessage, Object messageInput)
```

#### Parameters

| Name               | Type   | Description                                                              |
| ------------------ | ------ | ------------------------------------------------------------------------ |
| unformattedMessage | String | The base string to use for your log message                              |
| messageInput       | Object | The replacement text to use for 1 placeholder in the unformatted message |

#### Example

String formattedMessage &#x3D; new LogMessage(&#x27;Today is {0}&#x27;, System.today()).getMessage();

---

### `LogMessage(unformattedMessage, messageInput1, messageInput2)`

Constructor to handle dynamically formatting a string with 2 inputs

#### Signature

```apex
global LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2)
```

#### Parameters

| Name               | Type   | Description                                                                       |
| ------------------ | ------ | --------------------------------------------------------------------------------- |
| unformattedMessage | String | The base string to use for your log message                                       |
| messageInput1      | Object | The replacement text to use for the first placeholder in the unformatted message  |
| messageInput2      | Object | The replacement text to use for the second placeholder in the unformatted message |

#### Example

String unformattedMessage &#x3D; &#x27;my string with 2 inputs: {0} and {1}&#x27;;
String formattedMessage &#x3D; new LogMessage(unformattedMessage, &#x27;something&#x27;, &#x27;something else&#x27;).getMessage();

---

### `LogMessage(unformattedMessage, messageInput1, messageInput2, messageInput3)`

`SUPPRESSWARNINGS`

Constructor to handle dynamically formatting a string with 3 inputs

#### Signature

```apex
global LogMessage(String unformattedMessage, Object messageInput1, Object messageInput2, Object messageInput3)
```

#### Parameters

| Name               | Type   | Description                                                                       |
| ------------------ | ------ | --------------------------------------------------------------------------------- |
| unformattedMessage | String | The base string to use for your log message                                       |
| messageInput1      | Object | The replacement text to use for the first placeholder in the unformatted message  |
| messageInput2      | Object | The replacement text to use for the second placeholder in the unformatted message |
| messageInput3      | Object | The replacement text to use for the third placeholder in the unformatted message  |

#### Example

String unformattedMessage &#x3D; &#x27;my string with 3 inputs: {0} and then {1} and finally {2}&#x27;;
String formattedMessage &#x3D; new LogMessage(unformattedMessage, &#x27;something&#x27;, &#x27;something else&#x27;, &#x27;one more&#x27;).getMessage();

---

### `LogMessage(unformattedMessage, messageInputs)`

Constructor to handle dynamically formatting a string with a list of inputs

#### Signature

```apex
global LogMessage(String unformattedMessage, List<Object> messageInputs)
```

#### Parameters

| Name               | Type         | Description                                                                    |
| ------------------ | ------------ | ------------------------------------------------------------------------------ |
| unformattedMessage | String       | The base string to use for your log message                                    |
| messageInputs      | List<Object> | The list of inputs text to use for any placeholders in the unformatted message |

#### Example

String unformattedMessage &#x3D; &#x27;my string with 1 input: {0}&#x27;;
List&lt;Object&gt; arguments &#x3D; new List&lt;Object&gt;{ System.now() };
String formattedMessage &#x3D; new LogMessage(unformattedMessage, arguments).getMessage();

## Methods

### `getMessage()`

Returns the formatted string to use as the log entry&#x27;s message

#### Signature

```apex
global virtual String getMessage()
```

#### Return Type

**String**

String
