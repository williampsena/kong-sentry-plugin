local errlog = require "ngx.errlog"

local match = string.match
local fmt = string.format

local function is_blank(s)
  return s == nil or s == ''
end

local function is_match(content, pattern)
  if ngx.re.match(content, pattern) then
    return true
  else
    return false
  end
end

local function grep_content(content, pattern)
  local result = match(content, pattern)
  return result or ""
end

local function extract_request(content)
  return grep_content(content, 'request: "([^"]+)"')
end

local function extract_host(content)
  return grep_content(content, 'host: "([^"]+)"')
end

local function extract_client(content)
  return grep_content(content, 'client: (%d+.%d+.%d+.%d+)')
end

local function extract_error(content)
  return grep_content(content, '%[error%] (.*[^,]), client')
end

local function get_error_type(message)
  local error_type = ""

  if is_match(message, '\\[key-auth\\]') then
    error_type = "Key Auth Error"
  elseif is_match(message, '\\[cassandra\\]') then
    error_type = "Cassandra Error"
  elseif is_match(message, '\\[kong\\]') then
    error_type = "Kong Error"
  elseif is_match(message, '\\[lua\\]') then
    error_type = "Lua Error"
  else
    error_type = "Unknown Error"
  end

  return error_type
end

local function extract_sentry_error(message)
  local route = kong.router.get_route()
  local service = kong.router.get_service()
  local consumer = kong.client.get_consumer()

  local error_type = get_error_type(message)
  local error = extract_error(message) or message
  local request = extract_request(message)
  local error_title = fmt("%s %s", error_type, (request or error))
  local host = extract_host(message)
  local request_client = extract_client(message)

  local sentry_extra_context = {
    raw_error = message,
    message = error,
  }

  if not is_blank(request) then sentry_extra_context["request"] = request end
  if not is_blank(host) then sentry_extra_context["host"] = host end
  if not is_blank(request_client) then sentry_extra_context["client"] = request_client end
  if route then sentry_extra_context["route"] = route.name end
  if service then sentry_extra_context["service"] = service.name end
  if consumer then sentry_extra_context["consumer"] = consumer.name end

  return {
    error_title = error_title,
    error = error,
    sentry_extra_context = sentry_extra_context
  }
end

-- Get nginx log errors and translate to sentry errors
-- @returns 'array' with table errors
local function get_sentry_errors()
  --Get all err messages from global buffer during the tx, get_logs() clears them from the buffer upon success.
  local logs, err = errlog.get_logs()

  if err then
    kong.log.err("failed to get_sentry_errors: ", err)
    return nil
  end

  local errors = {}

  if not logs then return errors end

  for i = 1, #logs, 3 do
    local log_message = logs[i + 2]

    if string.match(log_message, "error") then
      table.insert(errors, extract_sentry_error(log_message))
    else
      kong.log.debug("Skip message: ", log_message)
    end
  end

  kong.table.clear(logs)

  return errors
end


-- Set log level to filter on nginx context
local function set_filter_error_log_level()
  local status, err = errlog.set_filter_level(ngx.ERR)

  if not status then
    kong.log.err("failed to set_filter_error_log_level:", err)
  end
end

return {
  set_filter_error_log_level = set_filter_error_log_level,
  get_sentry_errors = get_sentry_errors
}
