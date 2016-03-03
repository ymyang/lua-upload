--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/3/3
-- Time: 14:35
-- To change this template use File | Settings | File Templates.
--
local check = require 'download.check_download';

local token = get_token();
check.check_download(token);

local function get_token()
    if ngx.var.arg_st ~= nil then
        return ngx.var.arg_st;
    end

    if ngx.var.http_st ~= nil then
        return ngx.var.http_st;
    end

    if ngx.var.http_cookie ~= nil then
        return ngx.var.cookie_st;
    end
end