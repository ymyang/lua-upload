--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/3/3
-- Time: 14:39
-- To change this template use File | Settings | File Templates.
--
local check = require 'download.check_download';

local token = get_token();
check.check_download(token);


local function get_token()
    if ngx.var.arg_ct ~= nil then
        return ngx.var.arg_ct;
    end

    if ngx.var.http_ct ~= nil then
        return ngx.var.http_ct;
    end

    if ngx.var.http_cookie ~= nil then
        return ngx.var.cookie_ct;
    end
end
