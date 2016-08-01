--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/27
-- Time: 11:12
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local uploader = require 'upload.uploader';

-- upload file
local res_body, err = uploader.single_upload();

-- handle res
if not res_body then
    ngx.log(ngx.ERR, err);
    res_body = {
        status = 'err_500',
        msg = err
    };
    ngx.print(cjson.encode(res_body));
else
    ngx.print(res_body);
end
