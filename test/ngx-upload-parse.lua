--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/25
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';

ngx.req.read_body();

-- ngx.say(ngx.req.get_body_data());

local headers = ngx.req.get_headers();
ngx.req.set_header('Content-Type', headers['Content-Type']);
local res, err = ngx.location.capture('/apps/pub/upload/form', {
    method = ngx.HTTP_POST,
    body = ngx.req.get_body_data()
});

if not res then
    ngx.say('parse form:' .. err);
    ngx.exit(200);
end

ngx.say(res.body);
