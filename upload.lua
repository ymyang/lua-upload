--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/20
-- Time: 10:52
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local tracker = require('lib.fastdfs.tracker');
local storage = require('lib.fastdfs.storage');

local tk = tracker:new();
tk:set_timeout(3000);
local ok, err = tk:connect({host='127.0.0.1',port=22122});

if not ok then
    ngx.say('connect error:' .. err);
    ngx.exit(200);
end

local res, err = tk:query_storage_store();
if not res then
    ngx.say("query storage error:" .. err);
    ngx.exit(200);
end

local st = storage:new();
st:set_timeout(3000);
local ok, err = st:connect(res);
if not ok then
    ngx.say("connect storage error:" .. err);
    ngx.exit(200);
end

local args = ngx.req.get_uri_args();
local ext = args.fn:match(".+%.(%w+)$");

ngx.req.read_body();

local res, err = st:upload_by_buff(ngx.req.get_body_data(), ext);
if not res then
    ngx.say("upload error:" .. err);
    ngx.exit(200);
end

local param = {
    fileCategory = args.fc,
    fileId = args.fi,
    groupId = args.fi,
    parentId = args.pi,
    fileName = args.fn,
    fileSize = args.fs,
    fileGuid = res.group_name .. '/' .. res.file_name
};

local headers = ngx.req.get_headers();

ngx.req.set_header("Content-Type", "application/json;charset=utf-8");
ngx.req.set_header("ct", headers.ct);

local res, err = ngx.location.capture('/apps/file', {
    method = ngx.HTTP_POST,
    body = cjson.encode(param)
});

if not res then
    ngx.say("insert file error:" .. err);
    ngx.exit(200);
end

ngx.say(res.body);