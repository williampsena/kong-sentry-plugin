local typedefs = require "kong.db.schema.typedefs"

return {
  name = "sentry",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { sentry_dsn = typedefs.url({ required = true }) },
          { timeout = { type = "number", default = 10000 } },
          { keepalive = { type = "number", default = 60000 } },
          { queue = typedefs.queue() },
        },
      },
    },
  },
}
