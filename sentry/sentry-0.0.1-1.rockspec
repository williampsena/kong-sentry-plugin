package = "sentry"
version = "0.0.1-1"
supported_platforms = {"linux", "macosx"}

source = {
  url = "https://github.com/williampsena/kong-sentry-plugin",
  tag = "0.0.1"
}

description = {
  summary = "Kong plugin to inject kong errors on sentry.",
  homepage = "https://github.com/williampsena/kong-sentry-plugin",
  license = "MIT"
}

dependencies = {
  "lua ~> 5.1"
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.sentry.handler"] = "handler.lua",
    ["kong.plugins.sentry.client"] = "client.lua",
    ["kong.plugins.sentry.message"] = "message.lua",
    ["kong.plugins.sentry.schema"] = "schema.lua"
  }
}