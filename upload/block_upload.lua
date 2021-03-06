--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/8/5
-- Time: 18:09
-- To change this template use File | Settings | File Templates.
--

local cjson = require 'cjson';
local uploader = require 'upload.uploader';

-- upload file
local res_body, err = uploader.block_upload();

-- handle res
if not res_body then
    ngx.log(ngx.ERR, err);
    res_body = {
        status = 'err_500',
        msg = err
    };
end

ngx.print(cjson.encode(res_body));