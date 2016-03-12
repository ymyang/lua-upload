--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/3/12
-- Time: 15:14
-- To change this template use File | Settings | File Templates.
--
local string = require 'resty.string';
local aes = require 'resty.aes';

local aes_256 = aes:new('yliyun123', nil, aes.cipher(256, 'cbc'), nil, nil);

local str = 'group1/M00/00/00/wKgBeFal3_eAOkPMAADgSrKQmXQ200.jpg';

local e1 = aes_256:encrypt(str);

ngx.log(ngx.ERR, 'e1:' .. e1);

local e2 = string.to_hex(e1);

ngx.log(ngx.ERR, 'encrypted:' .. e2);

local d = aes_256:decrypt(e1);
ngx.log(ngx.ERR, 'decrypted:' .. d);

