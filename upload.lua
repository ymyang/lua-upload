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
local upload = require('resty.upload');

local key;
local filename;
local paramjson;
local filedata;

local chunk_size = 4096;

local form, err = upload:new(chunk_size);
if not form then
    ngx.log(ngx.ERR, "failed to new upload: ", err);
    ngx.exit(500);
end

form:set_timeout(1000); -- 1 sec

while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say('failed to read: ', err);
        return
    end

    if typ == 'header' then

        if res[1] == 'Content-Disposition' then
            key = res[2]:match('name=\"(.-)\"');
            if key == 'file' then
                filename = res[2]:match('filename=\"(.-)\"');
            end
        end

    elseif typ == 'body' then

        if key == 'param' then

            if paramjson == nil then
                paramjson = res;
            else
                paramjson = paramjson .. res;
            end

        elseif key == 'file' then

            if filedata == nil then
                filedata = res;
            else
                filedata = filedata .. res;
            end

        end

    elseif typ == 'part_end' then

    elseif typ == 'eof' then
        break

    else
        -- do nothing
    end
end

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


local ext = filename:match(".+%.(%w+)$");

local res, err = st:upload_by_buff(filedata, ext);
if not res then
    ngx.say("upload error:" .. err);
    ngx.exit(200);
end

local param = cjson.decode(paramjson);
param.fileName = filename;
param.fileGuid = res.group_name .. '/' .. res.file_name;

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