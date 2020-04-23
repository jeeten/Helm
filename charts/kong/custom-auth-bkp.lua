local utils = require "kong.tools.utils"
local reports = require "kong.reports"
local endpoints = require "kong.api.endpoints"
local arguments = require "kong.api.arguments"
local singletons = require "kong.singletons"
local api_helpers = require "kong.api.api_helpers"

local logging = require "logging"
local logger = logging.new(function(self, level, message)
    print(level, message)
    return true
  end)
local tab = { a = 1, b = 2 }
-- logger:debug(tab)



local ngx = ngx
local kong = kong
local type = type
local find = string.find
local pairs = pairs
local lower = string.lower
local setmetatable = setmetatable

local escape_uri = ngx.escape_uri
local unescape_uri = ngx.unescape_uri



-- local r_data = utils.deep_copy(data)

-- local bar = '{"Api":"User Details","Data":{"name":"Dasarathi","acls":[],"services":[]},"time":1586116880}'
kong.response.add_header("Content-Type", "application/json")
-- local db = kong.db
logger:debug(tab)
return function(self, db)
    local post = self.args and self.args.post
    -- this runs on each request
    local bar = '{"Api":"User Details","Data":{"name":"Dasarathi","acls":[],"services":[]},"time":1586116880}'
    -- local bar = '{"self":'+ post +',"db":'+ db+ '}'
    return kong.response.exit(200,bar)
end
