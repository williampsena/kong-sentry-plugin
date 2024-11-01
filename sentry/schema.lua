return {
  no_consumer = false,
  fields = {
    sentry_dsn = { type = "string", required = true },
    timeout = { type = "number", default = 10000 },
    keepalive = { type = "number", default = 60000 },
    retry_count = { type = "number", default = 2 },
    flush_timeout = { type = "number", default = 2 }
  }
}
