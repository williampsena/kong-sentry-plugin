local BatchQueue = require "kong.tools.batch_queue"
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

local function send_to_sentry(conf, sentry_error)
  if not sentry_error.error_title then return end

  return SentryClient.send_sentry_event(conf, sentry_error.error_title, sentry_error.sentry_extra_context)
end

local function has_valid_config(conf)
  if conf.http_endpoint or conf.sentry_key then
    return true
  else
    return false
  end
end

local function is_response_ok()
  if kong.response.get_status() < 499 then return true else return false end
end

function SentryHandler:init_worker()
  SentryMessage.set_filter_error_log_level()
end

function SentryHandler:log(conf)
  if is_response_ok() or not has_valid_config(conf) then return end
  -- FOR Testing > kong.log.err("Fake testing")

  SentryMessage.set_filter_error_log_level()
  local sentry_errors = SentryMessage.get_sentry_errors()

  if not sentry_errors then return end

  local queue_id = get_queue_id(conf)
  local q = queues[queue_id]

  if not q then
    -- batch_max_size <==> conf.queue_size
    local batch_max_size = 1
    local process = function(entries)
      local payload = entries[1]
      return send_to_sentry(conf, payload)
    end

    local opts = {
      retry_count    = conf.retry_count,
      flush_timeout  = conf.flush_timeout,
      batch_max_size = batch_max_size,
      process_delay  = 0,
    }

    local err

    q, err = BatchQueue.new(process, opts)

    if not q then
      kong.log.err("could not create queue: ", err)
      return
    end
    queues[queue_id] = q
  end

  for _, sentry_error in ipairs(sentry_errors) do
    q:add(sentry_error)
  end

  kong.table.clear(sentry_errors)
end

return SentryHandler
