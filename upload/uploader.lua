--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/27
-- Time: 10:58
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local fdfs = require 'fdfs.fastdfs';

local function parse_form()
    ngx.req.read_body();
    local headers = ngx.req.get_headers();
    ngx.req.set_header('Content-Type', headers['Content-Type']);
    local res, err = ngx.location.capture('/apps/pub/upload/form', {
        method = ngx.HTTP_POST,
        body = ngx.req.get_body_data()
    });

    if not res then
        return nil, 'parse form err:' .. err;
    end

    return cjson.decode(res.body);
end

local function upload_to_fdfs(file)
    local st, err = fdfs.get_storage();
    if not st then
        return nil, err;
    end

    local filename = file.originalname;

    local ext = filename:match('.+%.(%w+)$');

    local blockSize = 20000000; -- 20M
    local fileSize = file.size;

    local file, err = io.open(file.path, 'rb');
    if not file then
        return nil, 'open file ' .. file.path .. ' err:' .. err;
    end

    local file_info;

    if (fileSize < blockSize) then
        local filedata = file:read('*a');
        file:close();
        file = nil;

        local res, err = st:upload_by_buff(filedata, ext);
        st:set_keepalive(0, 5);
        if not res then
            return nil, 'storage upload by buff err: ' .. err;
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
                    return nil, 'storage upload_appender_by_buff err: ' .. err;
                end
                file_info = res;
            else
                local res, err = st:append_by_buff(file_info.group_name, file_info.file_name, data);
                if err then
                    st:set_keepalive(0, 5);
                    return nil, 'storage append_by_buff err: ' .. err;
                end
            end
            count = count + 1;
        until not data

        st:set_keepalive(0, 5);
        file:close();
        file = nil;
    end

    return file_info;
end

local function save_file(form, file_info, share)
    form.file.fileGuid = file_info.group_name .. '/' .. file_info.file_name;

    local headers = ngx.req.get_headers();
    ngx.req.set_header('Content-Type', 'application/json;charset=utf-8');

    local url = '';

    if not share then
        ngx.req.set_header('ct', headers.ct);
        url = '/apps/file';
    else
        url = '/apps/pub/share/file';
        ngx.req.set_header('st', headers.st);
    end

    local res, err = ngx.location.capture(url, {
        method = ngx.HTTP_POST,
        body = cjson.encode(form)
    });

    if not res then
        return nil, 'save file err: ' .. err;
    end

    return res.body;
end

local function single_upload(share)
    local form, err = parse_form();
    if not form then
        return nil, err;
    end

    local file_info, err = upload_to_fdfs(form.file);
    if not file_info then
        return nil, err;
    end

    return save_file(form, file_info, share);
end

return {
    single_upload = single_upload
};