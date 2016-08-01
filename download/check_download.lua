--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/3/1
-- Time: 14:25
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';

-- check download
local function check_download(token)
    -- dl args
    local key = ngx.var.arg_dl;

    if key == nil or key == '' then
        -- no dl args
        ngx.log(ngx.ERR, 'dl empty');
        ngx.exit(403);
    end

    if key == 'mb' then
        -- for mobile download
        return;
    end

    if token == nil or token == '' then
        -- no token
        ngx.log(ngx.ERR, 'token empty');
        ngx.exit(403);
    end

    -- invoke node service to get cached token
    local res = ngx.location.capture('/apps/pub/cache?key=' .. key);
    if res.status ~= 200 then
        ngx.log(ngx.ERR, 'get cache_token fail:' .. res.status);
        ngx.exit(500);
    end

    local body = cjson.decode(res.body);
    if body.status ~= 'ok' then
        -- get cached token err
        ngx.log(ngx.ERR, 'get cache_token err:' .. body.status);
        ngx.exit(500);
    end

    local cache_token = body.data;
    if cache_token == nil or cache_token == '' then
        -- no cached token
        ngx.log(ngx.ERR, 'key has expired! cache_token is nil');
        ngx.exit(403);
    end

    if token ~= cache_token then
        -- token no equal
        ngx.log(ngx.ERR, 'client token not match cache token! client token:' .. token .. ', cache_token:' .. cache_token);
        ngx.exit(403);
    end

end

return {
    check_download = check_download
};
