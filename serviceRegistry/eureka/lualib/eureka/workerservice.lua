local client = require 'eureka.client'

local _register, _renew, _quitclean

local eurekaclient, eurekaserver, instance, timeval, appid, instanceid
local quitcheckinterval = 5

_register = function(premature)
    if premature then
        return
    end
    local err
    eurekaclient, err = client:new(eurekaserver.host, eurekaserver.port, eurekaserver.uri, eurekaserver.auth)
    if not eurekaclient then
        ngx.log(ngx.ALERT, ('can not create client for app %s instance %s : %s'):format(appid, instanceid, err))
    else
        local ok, err = eurekaclient:register(appid, instance)
        if not ok then
            ngx.log(ngx.ALERT, ('can not register app %s instance %s : %s'):format(appid, instanceid, err))
        else 
            ngx.log(ngx.ALERT, ('register app %s instance %s successfully'):format(appid, instanceid))
        end
    end
end

_renew = function(premature)
    if premature then
        return
    end
    local eurekaclient = eurekaclient
    local ok, err = eurekaclient:heartBeat(appid, instanceid)
    if not ok or ngx.null == ok then
        ngx.log(ngx.ALERT, ('failed to renew app %s instance %s : %s'):format(appid, instanceid, err))
    else
        ngx.log(ngx.ALERT, ('renew app %s instance %s successfully'):format(appid, instanceid))
        ngx.timer.at(timeval, _renew)
    end
end

_quitclean = function(premature)
    if ngx.worker.exiting() then
        local eurekaclient = eurekaclient
        local ok, err = eurekaclient:deRegister(appid, instanceid)
        if not ok then
            ngx.log(ngx.ALERT, ('can not deregister app %s instance %s : %s'):format(appid, instanceid, err))
        else 
            ngx.log(ngx.ALERT, ('deregister app %s instance %s successfully'):format(appid, instanceid))
            return
        end
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

function _M.run(self, _eurekaserver, _instance)
    local cjson = require "cjson"
    instance = _instance
    eurekaserver = _eurekaserver
    timeval = tonumber(eurekaserver.timeval) or 30
    local configjson = cjson.decode(instance)
    local instancedata = configjson.instance
    appid = instancedata['app']
    instanceid = instancedata['instanceId']
    ngx.timer.at(0, _register)
    ngx.timer.at(timeval, _renew)
    ngx.timer.at(quitcheckinterval, _quitclean)
end

return _M
