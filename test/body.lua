--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/20
-- Time: 11:49
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';

ngx.req.read_body();
-- local post_args = ngx.req.get_post_args();
ngx.say(ngx.req.get_body_data());



