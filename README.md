# Sentry Kong Plugin

## Description
The plugin enables behavior to send unhandled errors to sentry using log level (error) at Nginx Lua Context.


## Testing
You can test plugin behaviors using docker, don't forget to set your URL and credentials at plugin configurations (./assets/kong.yml)

Run containers ->

```docker-compose up```

Send request to Kong, and will fail in order to sent event to sentry, because unknown HOST does not exits.

```curl -X GET http://localhost:8000```

Nice, you will see an error in your Sentry Self Hosted or Sentry.io.

## Configurations

| Attribute | Default | Description |
|-|-|-|
| http_endpoint | | Required sentry errors store url. |
| sentry_key | | Required sentry auth key, check on your DSN config. |
| timeout | 10000 | An optional timeout in milliseconds when sending data to the upstream server. |
| keepalive | 60000 | An optional value in milliseconds that defines how long an idle connection will live before being closed.|
| retry_count | 2 | Number of times to retry when sending data to the upstream server. |
| flush_timeout | 0 | Optional time in seconds. If queue_size > 1, this is the max idle time before sending a log with less than queue_size records. |

## Maintainers

Feel free to open issues, or refer to our Contribution Guidelines if you have any questions.

## References 

- https://docs.konghq.com/hub/kong-inc/http-log/
- https://github.com/Optum/kong-error-log

Well, thanks for sharing.