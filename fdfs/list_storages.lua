--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/5/30
-- Time: 16:27
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local fdfs = require 'fdfs.fastdfs';

local res_body;

local group_name;

local args = ngx.req.get_uri_args();
local group_name = args.group;

if not group_name then
    group_name = 'group1';
end

local storages, err = fdfs.list_servers(group_name);
if not storages then
    ngx.log(ngx.ERR, err);

    res_body = {
        status = 'err_500',
        msg = err
    };
else
    res_body = {
        status = 'ok',
        data = storages
    };
end

ngx.print(cjson.encode(res_body));
