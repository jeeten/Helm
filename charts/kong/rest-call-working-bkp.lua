local cjson = require "cjson"
local utils = require "kong.tools.utils"
local reports = require "kong.reports"
local endpoints = require "kong.api.endpoints"
local arguments = require "kong.api.arguments"
local singletons = require "kong.singletons"
local api_helpers = require "kong.api.api_helpers"
local http = require "resty.http"



local logging = require "logging"
local logger = logging.new(function(self, level, message)
    print(level, message)
    return true
  end)
 
local ngx = ngx
local kong = kong
local type = type
local find = string.find
local pairs = pairs
local lower = string.lower
local setmetatable = setmetatable

local escape_uri = ngx.escape_uri
local unescape_uri = ngx.unescape_uri
-- kong.service.request.set_header('x-service-id', ngx.ctx.service.id)

-- local headers = kong.response.get_header()
kong.response.add_header("Content-Type", "application/json")
-- kong.response.get_header(headers)
-- local db = kong.db
local services_dao = kong.db.services
local routes_dao = kong.db.routes
local consumers_dao = kong.db.consumers
local plugins_dao = kong.db.plugins

local consumer_id = ngx.ctx.authenticated_consumer.id


local res_data = {}
local acls = {}
local services = {}
local data = {}
local user_data = {}
local acls_data = {}
local service_data = {}

local dommy_data = {}
local albin = {}

  table.insert(albin, {["id"] = utils.uuid(), ["service"] = "activities"})
  table.insert(albin, {["id"] = utils.uuid(), ["service"] = "release-mgmt"})
  table.insert(albin, {["id"] = utils.uuid(), ["service"] = "test-mgmt"})
  table.insert(albin, {["id"] = utils.uuid(), ["service"] = "policy-mgmt"})
  table.insert(albin, {["id"] = utils.uuid(), ["service"] = "user-mgmt"})
  table.insert(albin, {["id"] = utils.uuid(), ["service"] = "artefact-mgmt"})


local snehil = {
  {["id"] = utils.uuid(), ["service"] = "activities"},
  {["id"] = utils.uuid(), ["service"] = "release-mgmt"},
  {["id"] = utils.uuid(), ["service"] = "test-mgmt"},
  {["id"] = utils.uuid(), ["service"] = "artefact-mgmt"},
}

dommy_data['albin'] = cjson.encode(albin)
dommy_data['snehil'] = cjson.encode(snehil)

local user, usr_err = consumers_dao:select{ id = consumer_id }
local plugin, plg_err = plugins_dao:select{ name = "acl" }
local plugin_name = "acl"
-- plugins_dao:select_statement
local conn = kong.db.connector
local rows, err = conn:query([[
  SELECT plugins.service_id,plugins.config ,services.name service FROM plugins INNER JOIN services ON services.id = plugins.service_id WHERE plugins.name = ']] .. plugin_name .. [['  and plugins.enabled = true;
]])


local group = {}
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

logger:debug("===========")
logger:debug(cjson.encode(group))
logger:debug("===========")


local username = user.username



if tostring(username) == "albin" then
  services= albin
elseif tostring(username) == "snehil" then
  services=snehil
else
  service_data['id'] = utils.uuid()
  service_data['service'] = "release-mgmt"
  table.insert(services,service_data)
end



-- [[ Getting all Groups ]]

local timeout = tonumber(60000)
-- logger:debug("======== host details =================")
-- local host = os.getenv("API_GATEWAY_KONG_ADMIN_SERVICE_HOST")
-- local port = os.getenv("API_GATEWAY_KONG_ADMIN_SERVICE_PORT")

-- logger:debug("======== host details ================="..host)
-- logger:debug("======== host details ================="..port)

local host = '10.203.0.6'
local port = tonumber(30159)
local method = "GET"
local path =  '/consumers/'..username..'/acls'
local content_type = "application/x-www-form-urlencoded"
local query = ""
local payload = ""
local keepalive = tonumber(10)
local err_msg = ""

local success = nil
local response_body = nil

local res_group = {}
local res_grp_data = {}

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
        val.services = "null"
        if group[val.group] then
          val.services = group[val.group]
        end
        table.insert(acls,val)
      end

    end

  end
end

-- table.insert(acls,acls_data)

user["acls"] = acls

-- table.insert(user,user_data)
-- data = user
data = cjson.encode(user)

return function()
    local res = '{"Api":"User Details","Data":'..data..',"time":1586116880}' 
    return kong.response.exit(200,res)
end
