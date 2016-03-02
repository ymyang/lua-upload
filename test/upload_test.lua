--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/20
-- Time: 10:52
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local tracker = require 'lib.fastdfs.tracker';
local storage = require 'lib.fastdfs.storage';

ngx.req.read_body();

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

local form = cjson.decode(res.body);


local tk = tracker:new();
tk:set_timeout(3000);
local ok, err = tk:connect({host='127.0.0.1',port=22122});

if not ok then
    ngx.say('connect error:' .. err);
    ngx.exit(200);
end

local res, err = tk:query_storage_store();
if not res then
    ngx.say('query storage error:' .. err);
    ngx.exit(200);
end

local st = storage:new();
st:set_timeout(3000);
local ok, err = st:connect(res);
if not ok then
    ngx.say('connect storage error:' .. err);
    ngx.exit(200);
end

local filename = form.file.originalname;

local ext = filename:match('.+%.(%w+)$');

local blockSize = 20000000;
local fileSize = form.file.size;

local file, err = io.open(form.file.path, 'rb');

local file_info;

if (fileSize < blockSize) then
    local filedata = file:read('*a');
    file:close();
    file = nil;

    local res, err = st:upload_by_buff(filedata, ext);
    st:set_keepalive(0, 5);
    if not res then
        ngx.say('upload error:' .. err);
        ngx.exit(200);
    end
    file_info = res;

else
    local data, count = nil, 0;
    repeat
        data = file:read(blockSize);
        if not data then
            break
        end
        if count == 0 then
            local res, err = st:upload_appender_by_buff(data, ext);
            if err then
                st:set_keepalive(0, 5);
                ngx.say('fail to invoke storage upload_appender_by_buff() ! err:' .. err);
            end
            file_info = res;
        else
            local res, err = st:append_by_buff(file_info.group_name, file_info.file_name, data);
            if err then
                st:set_keepalive(0, 5);
                ngx.say('fail to invoke storage append_by_buff() ! err:' .. err);
            end
        end
        count = count + 1;
    until not data

    st:set_keepalive(0, 5);
    file:close();
    file = nil;
end


form.file.fileGuid = file_info.group_name .. '/' .. file_info.file_name;

ngx.req.set_header('Content-Type', 'application/json;charset=utf-8');
ngx.req.set_header('ct', headers.ct);

local res, err = ngx.location.capture('/apps/file', {
    method = ngx.HTTP_POST,
    body = cjson.encode(form)
});

if not res then
    ngx.say('insert file error:' .. err);
    ngx.exit(200);
end

ngx.say(res.body);