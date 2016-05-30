--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/27
-- Time: 10:44
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local tracker = require 'lib.fastdfs.tracker';
local storage = require 'lib.fastdfs.storage';
local config = require 'config';

local trackers = config.fdfs.trackers;
local _index = 1;

local function connect_tracker(conf)
    local tk = tracker:new();
    tk:set_timeout(3000);

    local ok, err = tk:connect(conf);

    if not ok then
        return nil, 'connect_tracker:' .. cjson.encode(conf) .. ' [err]:' .. err;
    end
    return tk;
end

local function get_tracker()
    _index = _index + 1;
    if _index > #trackers then
        _index = 1;
    end

    local tk, err = connect_tracker(trackers[_index]);
    if tk then
        return tk;
    end

    ngx.log(ngx.ERR, "connect tracker: " .. cjson.encode(trackers[_index]) .. ' [err]:' .. err);

    if #trackers == 1 then
        return nil, "get_tracker fail: " .. cjson.encode(trackers[_index])
    end

    for i = 1, #trackers do
        if i ~= _index then
            tk, err = connect_tracker(trackers[i]);
            if tk then
                break;
            end
            ngx.log(ngx.ERR, "connect tracker: " .. cjson.encode(trackers[i]) .. ' [err]:' .. err);
        end
    end

    if tk then
        return tk;
    else
        return nil, 'get_tracker all fail, [err]:' .. err;
    end
end

local function get_storage()
    local tk, err = get_tracker();
    if not tk then
        return nil, err;
    end

    local res, err = tk:query_storage_store();
    if not res then
        return nil, 'query storage [err]:' .. err;
    end

    local st = storage:new();
    st:set_timeout(3000);
    local ok, err = st:connect(res);
    if not ok then
        return nil, 'connect storage [err]:' .. err;
    end

    return st;
end

local function list_groups()
    local tk, err = get_tracker();
    if not tk then
        return nil, err;
    end

    tk:set_v4(true);

    local groups, err = tk:list_groups();
    if not groups then
        return nil, 'list groups [err]:' .. err;
    end

    return groups;
end

local function list_servers(group_name)
    local tk, err = get_tracker();
    if not tk then
        return nil, err;
    end

    tk:set_v4(true);

    local servers, err = tk:list_servers(group_name);
    if not servers then
        return nil, 'list storages [err]:' .. err;
    end

    return servers;
end

return {
    get_storage = get_storage,
    list_groups = list_groups,
    list_servers = list_servers
};