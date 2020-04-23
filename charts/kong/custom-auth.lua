local cjson = require "cjson"
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
local consumer_id = ngx.ctx.authenticated_consumer.id
-- local consumer_id = ngx.ctx.authenticated_credential.consumer_id
logger:debug('-- Consumer id --')
logger:debug()
logger:debug(consumer_id)
logger:debug()
logger:debug('-- Consumer id --')

local res_data = {}
local acls = {}
local services = {}
local data = {}
local user_data = {}
local acls_data = {}
local service_data = {}

local user, err = consumers_dao:select{ id = consumer_id }

service_data['id'] = 10
service_data['name'] = "release-mgmt"

table.insert(services,service_data)

acls_data["id"] = 2
acls_data["name"] = "admin"
acls_data["service"] = services

table.insert(acls,acls_data)

user["acls"] = acls

-- table.insert(user,user_data)

data = cjson.encode(user)

return function()
    local res = '{"Api":"User Details","Data":'..data..',"time":1586116880}' 
    return kong.response.exit(200,res)
end
