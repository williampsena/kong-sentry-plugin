local cjson = require "cjson"
local url = require "socket.url"
local http = require "resty.http"
local table_clear = require "table.clear"
local uuid = require "kong.tools.uuid"

local parsed_urls_cache = {}
local headers_cache = {}
local params_cache = {
    ssl_verify = false,
    headers = headers_cache,
}

local fmt = string.format

-- Parse host url.
-- @param `url` host url
-- @return `parsed_url` a table with host details:
-- scheme, host, port, path, query, userinfo
local function parse_url(host_url)
    local parsed_url = parsed_urls_cache[host_url]

    if parsed_url then
        return parsed_url
    end

    parsed_url = url.parse(host_url)
    
    if not parsed_url.port then
        if parsed_url.scheme == "http" then
            parsed_url.port = 80
        elseif parsed_url.scheme == "https" then
            parsed_url.port = 443
        end
    end
    if not parsed_url.path then
        parsed_url.path = "/"
    end

    parsed_urls_cache[host_url] = parsed_url

    return parsed_url
end

-- Sent sentry event
-- @param `conf` plugin configurations
-- @param `message` error message
-- @param `extra` error extra context
-- @return `tuple` a tuple that indicates success or failed message.
-- succes, err_msg
local function send_sentry_event(conf, message, extra)

    local http_endpoint = conf.sentry_dsn
    local parsed_url = parse_url(http_endpoint)
    local host = parsed_url.host
    local port = tonumber(parsed_url.port)
    local sentry_key = parsed_url.user
    if not sentry_key then
        return nil, "failed to parse DSN url: " .. conf.sentry_dsn
    end

    local httpc = http.new()
    httpc:set_timeout(conf.timeout)

    local event_id = string.gsub(uuid.uuid(), "-", "")
    local timestamp = ngx.now()
    local event = cjson.encode({
        event_id = event_id,
        timestamp = timestamp,
        platform = "other",
        server_name = kong.node.get_hostname(),
        logentry = {
            message = message,
        },
        extra = extra,
    })
    local event_header = cjson.encode({
        event_id = event_id,
        dsn = conf.sentry_dsn,
    })
    local type_header = cjson.encode({
        type = "event",
        length = #event,
    })
    local payload = event_header .. "\n" .. type_header .. "\n" .. event

    table_clear(headers_cache)

    headers_cache["Content-Type"] = "application/x-sentry-envelope"
    headers_cache["X-Sentry-Auth"] = "Sentry sentry_version=7, sentry_key=" .. sentry_key .. ", sentry_timestamp=" .. timestamp

    params_cache.method = "POST"
    params_cache.body = payload
    params_cache.keepalive_timeout = conf.keepalive

    local url = fmt("%s://%s:%d/api%s/envelope/", parsed_url.scheme, parsed_url.host, parsed_url.port, parsed_url.path)
    local res, err = httpc:request_uri(url, params_cache)

    if not res then
        return nil, "failed sentry request to " .. host .. ":" .. tostring(port) .. ": " .. err
    end

    -- always read response body, even if we discard it without using it on success
    local response_body = res.body
    local success = res.status < 400
    local err_msg

    if not success then
        err_msg = "request to " .. host .. ":" .. tostring(port) ..
            " returned status code " .. tostring(res.status) .. " and body " ..
            response_body
    end

    kong.log.notice("Sentry error dispatched:", payload)

    return success, err_msg
end

return { send_sentry_event = send_sentry_event }
