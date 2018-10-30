# SpringCloudOpenresty

A tool for registering application which run inside openresty as a spring cloud microservice, especially restful APIs developed by PHP. 

there are  two versions, one is compatible for eureka, another one for Spring cloud consul.

project tested on Spring Cloud version--Finchley.SR1(2.0.5.RELEASE).


usage:

make sure you have install openresty and php 7.0&FPM successfully

# for Spring cloud consul:

## 1. copy all files(include directory) inside serviceRegistry/consul/lualib to your your openresty lualib directory maybe /usr/local/openresty/lualib

## 2. change your nginx.conf file same as serviceRegistry/consul/conf/nginx.conf,  please pay your attention to the block
```
init_worker_by_lua_block {
    if 0 == ngx.worker.id() then 
        local w = require 'consul.workerservice'
        local filePath = "/usr/local/openresty/nginx/conf/serviceInstance.json"
	      local consulUrl = "http://192.168.91.128:8500"
	      local file1 = io.input(filePath)
	      local serviceConfig = io.read("*a")
        w.run(consulUrl, serviceConfig)
    end
}
```

change the vairable "filePath"--"/usr/local/openresty/nginx/conf/serviceInstance.json" to your own service configuration location.
change the variable "consulUrl" -- "http://192.168.91.128:8500" to your own consul client url

## 3. change your serviceInstance.json as your environment, for example:
```
{
    "ID":"openresty-consul-test-app-192.168.91.129:80",
    "Name":"openresty-consul-test-app",
    "Tags":[
        "secure=false"
    ],
    "Address":"192.168.91.129",
    "Port":80,
    "Check":{
        "Interval":"10s",
        "HTTP":"http://192.168.91.129:80/health"
    }
}
```
don't change any key in this json, change the value according to your environment.

please make sure the check url (it is "http://192.168.91.129:80/health" in my example） is accessible url, I added a block in nginx.conf as below:

```
location = /health {
    echo 'alive';
}
```
## 4. copy files inside serviceRegistry/html to your web root directory, test them.


for eureka, the steps are almost same as consul guide, ignore ...




