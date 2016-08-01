--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/3/2
-- Time: 16:08
-- To change this template use File | Settings | File Templates.
--

-- store dir
local store_path = ngx.var[1];
local base_path = ngx.var[store_path];

-- file path
local file_path = base_path .. '/data/' .. ngx.var[2];

-- md5sum
local handle = io.popen('md5sum -b ' .. file_path, 'r');
local res = handle:read('*all');
handle:close();

ngx.header.content_type = 'text/html;charset=utf-8';
ngx.print(string.sub(res, 1, 32));
