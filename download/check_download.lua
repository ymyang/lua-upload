--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/3/1
-- Time: 14:25
-- To change this template use File | Settings | File Templates.
--

local key = ngx.var.arg_dl;

if key == nil or key == '' then
    return;
end

local token = get_token();

if token == nil or token == '' then
    ngx.exit(403);
end

local res = ngx.location.capture("/apps/pub/cache?key=" .. key);
if res.status ~= 200 then
    ngx.log(ngx.ERR, 'get cache_token fail:' .. res.status);
    ngx.exit(500);
end

local body = cjson.decode(res.body);
if body.status ~= 'ok' then
    ngx.log(ngx.ERR, 'get cache_token err:' .. body.status);
    ngx.exit(500);
end

local cache_token = body.data;
if cache_token == nil or cache_token == '' then
    ngx.log(ngx.ERR, 'key has expired! cache_token is nil');
    ngx.exit(403);
end

if token ~= memc_token then
    ngx.log(ngx.ERR, 'client token not match cache token!');
    ngx.exit(403);
end

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
