# Summary

A realm records nothing about sign-ins or administrator changes until events are turned on, and it records only from that moment. Two kinds of events cover the two kinds of question.

## What you learned

User events record what users and clients do. `eventsEnabled` turns them on, `enabledEventTypes` chooses what to store, and `eventsExpiration` sets how many seconds to keep them. Types come in pairs: `LOGIN` and `LOGIN_ERROR`, `REFRESH_TOKEN` and `REFRESH_TOKEN_ERROR`, `CODE_TO_TOKEN` and `CODE_TO_TOKEN_ERROR`. The `kcadm get events` call reads them with the filters `type`, `user`, `client`, `dateFrom` and `dateTo`. The time of an event is in milliseconds.

Admin events record changes made through the Admin API. `adminEventsEnabled` turns them on, and `adminEventsDetailsEnabled` also stores the request body as the representation. Each event has an operation type, a resource type, a resource path and the details of who made the change. The `kcadm get admin-events` call reads them.

The token endpoint hides the cause of a failure behind `invalid_grant`. The `error` field of the `LOGIN_ERROR` event names the cause, for example `invalid_user_credentials`, `user_not_found` or `user_disabled`.

Event listeners receive every event. The `jboss-logging` listener writes lines to the server log, with errors at the warning level. The realm's `eventsListeners` list replaces itself when you set it, so include every listener you still need. Expiration and clearing keep the stored events from growing, and cleared events cannot be recovered.

- Events exist only from the moment they are turned on.
- Read the event, not the HTTP response, to find a cause.
- Details can hold personal data, so enable them with care.

<!-- astrona:playground:destroy -->
