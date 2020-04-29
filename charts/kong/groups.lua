kong.response.add_header("Content-Type", "application/json")
local process_start_time = os.time()
-- [[ required libraries ]]
local cjson = require "cjson"
local http = require "resty.http"

-- [[ libraries ]]
-- local utils = require "kong.tools.utils"
-- local reports = require "kong.reports"
-- local endpoints = require "kong.api.endpoints"
-- local arguments = require "kong.api.arguments"
-- local singletons = require "kong.singletons"
-- local api_helpers = require "kong.api.api_helpers"

-- [[ custome logging ]]
local logging = require "logging"
local logger = logging.new(function(self, level, message)
    print(level, message)
    return true
  end)

-- [[ not requied packages ]]
-- local escape_uri = ngx.escape_uri
-- local unescape_uri = ngx.unescape_uri
-- local services_dao = kong.db.services
-- local routes_dao = kong.db.routes
-- local plugins_dao = kong.db.plugins

-- [[ common used packages ]]
local type = type
local find = string.find
local lower = string.lower
local setmetatable = setmetatable

-- [[ requied packages ]]
local ngx = ngx
local kong = kong
local pairs = pairs
local consumers_dao = kong.db.consumers
local conn = kong.db.connector


-- [[ local varaible diclaration ]]

local acls = {}
local data = {}
local group = {}
local group_index = {}

local plugin_name = "acl"


-- [[ custome query for service and group maping ]]

local rows, conerr = conn:query([[
  SELECT plugins.service_id,plugins.config ,services.name service FROM plugins INNER JOIN services ON services.id = plugins.service_id WHERE plugins.name = ']] .. plugin_name .. [['  and plugins.enabled = true;
]])

-- [[ iterating the result row  ]]

for key,val in pairs(rows) do
  for gk,gv in pairs(val.config.whitelist) do
    if group_index[gv] == nil then
        group_index[gv] = gv
        table.insert(group,{["group"] = gv})
    end
  end

end

data = cjson.encode(group)

logger:debug(data)

local process_end_time = os.time()
local process_prepared_time = process_end_time - process_start_time
-- [[ returning response ]]
return function()
    local response = '{"Api":"Group Details","Data":'..data..',"time":'..process_prepared_time..'}' 
    return kong.response.exit(200,response)
end
