Nebula Logger includes 4 permission sets - these are intended to cover the most common scenarios of granting users partial or full access to the logging system & its related objects.

1.  `LoggerLogCreator` provides the explicit access to all Apex classes used to generate logs via Apex, Lightning Components, Flow or Process Builder
2.  `LoggerEndUser` provides access to generate logs, as well as read-only access to any log records shared with the user.
3.  `LoggerLogViewer` provides view-all access (read-only) to all log records. This does **not** provide access to generate logs.
4.  `LoggerAdmin` provides view-all and modify-all access to all log records.
