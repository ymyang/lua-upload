--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/5/30
-- Time: 16:22
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local fdfs = require 'fdfs.fastdfs';

local res_body;

local groups, err = fdfs.list_groups();
if not groups then
    ngx.log(ngx.ERR, err);

    res_body = {
        status = 'err_500',
        msg = err
    };
else
    res_body = {
        status = 'ok',
        data = groups
    };
end

ngx.print(cjson.encode(res_body));
