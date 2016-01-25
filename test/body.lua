--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/20
-- Time: 11:49
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local upload = require('resty.upload');

local chunk_size = 4096;

local form, err = upload:new(chunk_size);
if not form then
    ngx.log(ngx.ERR, "failed to new upload: ", err);
    ngx.exit(500);
end

form:set_timeout(1000); -- 1 sec

local key;
local filename;
local param;
local data;

while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say('failed to read: ', err);
        return
    end

    if typ == 'header' then

        if res[1] == 'Content-Disposition' then
            key = res[2]:match('name=\"(.-)\"');
            -- ngx.say('key: ', key);
            if key == 'file' then
                filename = res[2]:match('filename=\"(.-)\"');
            end
        end

    elseif typ == 'body' then

        if key == 'param' then

            if param == nil then
                param = res;
            else
                param = param .. res;
            end

        elseif key == 'file' then

            if data == nil then
                data = res;
            else
                data = data .. res;
            end

        end

    elseif typ == 'part_end' then

    elseif typ == 'eof' then
        break

    else
        -- do nothing
    end
end

ngx.say('param: ', param);
ngx.say('filename: ', filename);

--[[local filename,content
while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say("failed to read: ", err)
        return
    end

    if typ == "header" then
        if res[1] == "Content-Disposition" then
            key = match(res[2], "name=\"(.-)\"")
            filename = match(res[2], "filename=\"(.-)\"")

        elseif res[1] == "Content-Type" then
            filetype = res[2]
        end

        if filename and filetype then
            if not self.extname then
                self.extname = filename:match(".+%.(%w+)$")
            end
            value = "userdata"
        end

    elseif typ == "body" then
        if value == "userdata" then
            if content == nil then
                content = res
            else
                content = content .. res
            end
        end

        --elseif typ == "part_end" then

    elseif typ == "eof" then
        --self.send_fastdfs(content, self.extname)
        break
    end
end

ngx.say('filename:' .. filename);]]

-- ngx.req.read_body();
-- local post_args = ngx.req.get_post_args();
-- ngx.say(ngx.req.get_body_data());

-- local file = ngx.req.get_body_file()
-- if file then
--     ngx.say("body is in file ", file);
-- else
--     ngx.say("no body found");
-- end



