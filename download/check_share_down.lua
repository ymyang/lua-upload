--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/3/3
-- Time: 14:35
-- To change this template use File | Settings | File Templates.
--
local check = require 'download.check_download';

-- get token
local function get_token()
    local headers = ngx.req.get_headers();
    -- ngx.log(ngx.ERR, 'headers:' .. cjson.encode(headers));
    if headers.st ~= nil then
        -- token in header
        return headers.st;
    end

    local args = ngx.req.get_uri_args();
    -- ngx.log(ngx.ERR, 'args:' .. cjson.encode(args));
    if args.st ~= nil then
        -- token in url args
        return args.st;
    end

    if ngx.var.http_cookie ~= nil then
        -- token in cookie
        return ngx.var.cookie_st;
    end
end

-- token
local token = get_token();
-- check download
check.check_download(token);
