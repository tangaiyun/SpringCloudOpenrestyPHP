local http = require 'resty.http'

local _register, _quitclean

local quitcheckinterval = 5

local consulurl, instance, registerpath, deregisterpath, appname, appid

_register = function(premature)
    if premature then
        return
    end
	local httpc, err = http.new()
    if not httpc then
        ngx.log(ngx.ERR, 'can not create http client') 
        return
    end
    local headers = {}
    headers['Accept'] = 'application/json'
    headers['Content-Type'] = 'application/json'
    local res, err = httpc:request_uri(consulurl, {
        version = 1.1,
        method = 'PUT',
        headers = headers,
        path = registerpath,
        query = nil,
        body = instance,
    })
    if 200 == res.status then
        ngx.log(ngx.ALERT, ('register %s with id: %s successfully'):format(appname, appid))
    end	
    if 400 == res.status then
        ngx.log(ngx.ERR, 'register failed, maybe your service config is incorrect')
    end
end

_quitclean = function(premature)
    if ngx.worker.exiting() then
        local httpc, err = http.new()
        if not httpc then
            ngx.log(ngx.ERR, 'can not create http client')
            return
        end
        local res, err = httpc:request_uri(consulurl, {
			version = 1.1,
			method = 'PUT',
			headers = nil,
			path = deregisterpath,
			query = nil,
			body = nil,
		})
        if 200 == res.status then
            ngx.log(ngx.ALERT, ('deregister %s with id: %s successfully'):format(appname, appid))
        end
        return
    end	
    if not ngx.worker.exiting() then   
        local ok, err = ngx.timer.at(quitcheckinterval, _quitclean)
        if not ok then
            ngx.log(ngx.ERR, "failed to create timer: ", err)
        end
    end
end

local _M = {
    ['_VERSION'] = '0.0.1'
}

function _M.run( _consulurl, _instance)
    local cjson = require "cjson"
    consulurl = _consulurl
    instance = _instance
    local json = cjson.decode(instance)
    appname = json.Name
    appid = json.ID
    registerpath = '/v1/agent/service/register'
    deregisterpath = '/v1/agent/service/deregister/' .. appid
    ngx.timer.at(0, _register)
    ngx.timer.at(quitcheckinterval, _quitclean)
end

return _M
