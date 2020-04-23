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
-- local logging = require "logging"
-- local logger = logging.new(function(self, level, message)
--     print(level, message)
--     return true
--   end)

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

local query = ""
local payload = ""

local success = nil
local response_body = nil

local acls = {}
local data = {}
local group = {}
local res_group = {}
local res_grp_data = {}

local timeout = tonumber(60000)
local keepalive = tonumber(10)
local port = tonumber(30159)
local host = '10.203.0.6'
local method = "GET"
local content_type = "application/x-www-form-urlencoded"
local plugin_name = "acl"

local consumer_id = ngx.ctx.authenticated_consumer.id

-- local plugin, plg_err = plugins_dao:select{ name = "acl" }
local user, usr_err = consumers_dao:select{ id = consumer_id }
local username = user.username
local path =  '/consumers/'..username..'/acls'

-- [[ custome query for service and group maping ]]

local rows, conerr = conn:query([[
  SELECT plugins.service_id,plugins.config ,services.name service FROM plugins INNER JOIN services ON services.id = plugins.service_id WHERE plugins.name = ']] .. plugin_name .. [['  and plugins.enabled = true;
]])

-- [[ iterating the result row  ]]

for key,val in pairs(rows) do

  for gk,gv in pairs(val.config.whitelist) do
      if group[gv] == nil then
          group[gv] = {}
          table.insert(group[gv],{["id"] = val.service_id , ["service"]=val.service})
      else
          table.insert(group[gv],{["id"] = val.service_id , ["service"]=val.service})
      end
  end

end

-- [[ http api call for acl ]]
local httpc = http.new()
httpc:set_timeout(timeout)
local res = nil
local ok, err = httpc:connect(host, port)
if ok then

  res, err = httpc:request({
    method = method,
    path = path,
    query = query,
    headers = {
        ["Content-Type"] = content_type,
        ["Content-Length"] = #payload,
    },
    keepalive_timeout = timeout,
    keepalive_pool = keepalive,
    body = payload,
  })

  if res then
    response_body = res:read_body()
    success = res.status < 400

    if success then
      res_group = cjson.decode(response_body)
      res_grp_data = res_group.data

      for key,val in pairs(res_grp_data) do
        val.created_at = nil
        val.consumer=nil
        val.tags=nil

        val.services = {}
        if group[val.group] then
          val.services = group[val.group]
        end
   
        table.insert(acls,val)
      end

    end

  end
end

user["acls"] = acls
data = cjson.encode(user)

local process_end_time = os.time()
local process_prepared_time = process_end_time - process_start_time
-- [[ returning response ]]
return function()
    local response = '{"Api":"User Details","Data":'..data..',"time":'..process_prepared_time..'}' 
    return kong.response.exit(200,response)
end
