local plugin_name = "sentry"
local package_name = "sentry"
local package_version = "0.0.1"
local rockspec_revision = "1"

local github_account_name = "williampsena"
local github_repo_name = "kong-plugin"
local git_checkout = package_version == "dev" and "master" or package_version


package = package_name
version = package_version .. "-" .. rockspec_revision
supported_platforms = { "linux", "macosx" }
source = {
  url = "git+https://github.com/"..github_account_name.."/"..github_repo_name..".git",
  branch = git_checkout,
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
    ["kong.plugins."..plugin_name..".handler"] = "kong/plugins/"..plugin_name.."/handler.lua",
    ["kong.plugins."..plugin_name..".schema"] = "kong/plugins/"..plugin_name.."/schema.lua",
    ["kong.plugins."..plugin_name..".client"] = "kong/plugins/"..plugin_name.."/client.lua",
    ["kong.plugins."..plugin_name..".message"] = "kong/plugins/"..plugin_name.."/message.lua",
  }
}