local helpers = require "spec.helpers"
local PLUGIN_NAME = "sentry"

for _, strategy in helpers.all_strategies() do
    if strategy ~= "cassandra" then
        describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
            local client

            lazy_setup(function()
                original_debug = kong.log.debug

                local bp = helpers.get_db_utils(
                               strategy == "off" and "postgres" or strategy,
                               nil, {PLUGIN_NAME})

                local service = bp.services:insert{
                    name = "mock-service",
                    host = helpers.mock_upstream_host,
                    port = helpers.mock_upstream_port,
                    protocol = helpers.mock_upstream_protocol
                }

                -- Inject a test route. No need to create a service, there is a default
                -- service which will echo the request.
                local ok_route = bp.routes:insert({
                    protocols = {"http"},
                    paths = {"/ok"},
                    service = service
                })

                local error_route = bp.routes:insert({
                    protocols = {"http"},
                    paths = {"/error"},
                    service = service
                })

                -- add the plugin to test to the route we created
                -- route that returns ok, sentry should skip
                bp.plugins:insert{
                    name = PLUGIN_NAME,
                    route = {id = ok_route.id},
                    config = {
                        http_endpoint = "https://localhost:4000/ok",
                        sentry_key = "foo"
                    }
                }

                -- route that returns error and can send it to sentry
                bp.plugins:insert{
                    name = PLUGIN_NAME,
                    route = {id = error_route.id},
                    config = {
                        http_endpoint = "https://localhost:4000/error",
                        sentry_key = "testing"
                    }
                }

                bp.plugins:insert{
                    name = "request-termination",
                    route = {id = error_route.id},
                    config = {
                        status_code = 502,
                        content_type = "application/json",
                        body = '{"error": "Bad Gateway"}'
                    }
                }

                -- start kong
                assert(helpers.start_kong({
                    -- set the strategy
                    database = strategy,
                    -- use the custom test template to create a local mock server
                    nginx_conf = "spec/fixtures/custom_nginx.template",
                    -- set directive to capture error log
                    nginx_http_lua_capture_error_log = "100k",
                    -- make sure our plugin gets loaded
                    plugins = "bundled," .. PLUGIN_NAME,
                    -- write & load declarative config, only if 'strategy=off'
                    declarative_config = strategy == "off" and
                        helpers.make_yaml_file() or nil
                }))
            end)

            lazy_teardown(function() helpers.stop_kong(nil, true) end)

            before_each(function() client = helpers.proxy_client() end)

            after_each(function() if client then client:close() end end)

            describe("/ok", function()
                it("should skip plugin", function()
                    local r =
                        client:get("/ok", {headers = {host = "localhost"}})

                    assert.response(r).has.status(200)
                end)
            end)

            describe("/error", function()
                it("should send sentry error", function()
                    local r = client:get("/error",
                                         {headers = {host = "localhost"}})

                    assert.response(r).has.status(502)

                end)
            end)
        end)

    end
end
