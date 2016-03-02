--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/20
-- Time: 11:49
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local upload = require 'resty.upload';

local key;
local filename;
local paramjson;
local filedata;

local chunk_size = 4096;

local form, err = upload:new(chunk_size);
if not form then
    ngx.log(ngx.ERR, 'failed to new upload: ', err);
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

ngx.say('param: ', paramjson);
ngx.say('filename: ', filename);

-- ngx.req.read_body();
-- local post_args = ngx.req.get_post_args();
-- ngx.say(ngx.req.get_body_data());




