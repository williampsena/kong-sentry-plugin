# 🦍 Kong Sentry Plugin 

## Description
The plugin enables the behavior of sending unhandled errors to sentry via log level (error) in the Nginx Lua Context.


## Testing
You can test plugin behaviors using docker; just remember to set your URL and credentials at plugin configurations `./assets/kong.yml`.

- Run containers

```shell
dockercompose up
```

Send request to Kong, and will fail in order to sent event to sentry, because unknown HOST does not exits.

```shell
curl -X GET http://localhost:8000
```

You will notice an error in your Sentry Self Hosted or Sentry.io.

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

If you have any queries, please submit an issue or see our Contribution Guidelines.

## References 

- https://docs.konghq.com/hub/kong-inc/http-log/
- https://github.com/Optum/kong-error-log
- https://sentry.io/

Well, thanks for sharing.