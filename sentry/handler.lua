local Queue = require "kong.tools.queue"
local SentryClient = require "kong.plugins.sentry.client"
local SentryMessage = require "kong.plugins.sentry.message"

local SentryHandler = {}

SentryHandler.VERSION  = "0.0.1"
SentryHandler.PRIORITY = 12

local queues = {}
local fmt = string.format

local function get_queue_id(conf)
  return fmt("%s:%s", conf.http_endpoint, conf.sentry_key)
end

local function send_to_sentry(conf, entries)
  local sentry_error = entries[1]
  if not sentry_error or not sentry_error.error_title then
    return true, "Cannot send error log to Sentry because failed to parse error message"
  end
  return SentryClient.send_sentry_event(conf, sentry_error.error_title, sentry_error.sentry_extra_context)
end

local function has_valid_config(conf)
  if conf.sentry_dsn then
    return true
  else
    return false
  end
end

function SentryHandler:init_worker()
  SentryMessage.set_filter_error_log_level()
end

function SentryHandler:log(conf)

  if not has_valid_config(conf) then return end

  local sentry_errors = SentryMessage.get_sentry_errors()
  if not sentry_errors then return end

  local queue_id = get_queue_id(conf)
  local queue_conf = conf.queue
  queue_conf.name = queue_id
  queue_conf.max_batch_size = 1
  
  for _, sentry_error in ipairs(sentry_errors) do

    local ok, err = Queue.enqueue(
      queue_conf,
      send_to_sentry,
      conf,
      sentry_error
    )
    if not ok then
      kong.log.err("Failed to enqueue log entry to Sentry: ", err)
    end
  
  end

  kong.table.clear(sentry_errors)
end

return SentryHandler
