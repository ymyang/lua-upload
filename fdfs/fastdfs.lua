--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/27
-- Time: 10:44
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local tracker = require('lib.fastdfs.tracker');
local storage = require('lib.fastdfs.storage');
local config = require 'config';

local function get_tracker()
    local tk = tracker:new();
    tk:set_timeout(3000);

    local ok, err = tk:connect(config.fdfs.tracker);

    if not ok then
        return nil, 'failed to connect to tracker:' .. cjson.encode(config.fdfs.tracker) .. ' err:' .. err;
    end
    return tk;
end

local function get_storage()
    local tk, err = get_tracker();
    if not tk then
        return nil, err;
    end

    local res, err = tk:query_storage_store();
    if not res then
        return nil, 'query storage err:' .. err;
    end

    local st = storage:new();
    st:set_timeout(3000);
    local ok, err = st:connect(res);
    if not ok then
        return nil, 'connect storage err:' .. err;
    end

    return st;
end

return {
    get_storage = get_storage
};