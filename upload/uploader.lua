--
-- Created by IntelliJ IDEA.
-- User: yang
-- Date: 2016/1/27
-- Time: 10:58
-- To change this template use File | Settings | File Templates.
--
local cjson = require 'cjson';
local utils = require 'lib.fastdfs.utils'
local fdfs = require 'fdfs.fastdfs';

-- parse form
local function parse_form()
    ngx.req.read_body();
    local headers = ngx.req.get_headers();
    ngx.req.set_header('Content-Type', headers['Content-Type']);

    -- invoke node service
    local res, err = ngx.location.capture('/apps/pub/upload/form', {
        method = ngx.HTTP_POST,
        body = ngx.req.get_body_data()
    });

    if not res then
        return nil, 'parse form err:' .. err;
    end

    return cjson.decode(res.body);
end

-- upload file to FastDFS
local function upload_to_fdfs(file)
    -- get storage
    local st, err = fdfs.get_storage();
    if not st then
        return nil, err;
    end

    -- file name
    local filename = file.originalname;

    -- file ext name
    local ext = filename:match('.+%.(%w+)$');

    -- block size
    local blockSize = 20000000; -- 20M
    -- file size
    local fileSize = file.size;

    local f, err = io.open(file.path, 'rb');
    if not f then
        -- open file err
        return nil, 'open file ' .. file.path .. ' err:' .. err;
    end

    local file_info;

    if (fileSize < blockSize) then
        -- one block
        local filedata = f:read('*a');
        f:close();
        f = nil;

        local res, err = st:upload_by_buff(filedata, ext);
        st:set_keepalive(0, 5);
        if not res then
            return nil, 'storage upload by buff err: ' .. err;
        end
        file_info = res;

    else
        -- multi blocks
        local data, count = nil, 0;
        repeat
            data = f:read(blockSize);
            if not data then
                break
            end
            if count == 0 then
                -- first block
                local res, err = st:upload_appender_by_buff(data, ext);
                if err then
                    st:set_keepalive(0, 5);
                    return nil, 'storage upload_appender_by_buff err: ' .. err;
                end
                file_info = res;
            else
                -- append blocks
                local res, err = st:append_by_buff(file_info.group_name, file_info.file_name, data);
                if err then
                    st:set_keepalive(0, 5);
                    return nil, 'storage append_by_buff err: ' .. err;
                end
            end
            count = count + 1;
        until not data

        st:set_keepalive(0, 5);
        f:close();
        f = nil;
    end

    return file_info;
end

-- save file to db
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

    -- invoke node service
    local res, err = ngx.location.capture(url, {
        method = ngx.HTTP_POST,
        body = cjson.encode(form)
    });

    if not res then
        return nil, 'save file err: ' .. err;
    end

    return res.body;
end

-- upload single file
local function single_upload(share)
    -- parse form data
    local form, err = parse_form();
    if not form then
        return nil, err;
    end

    -- upload file to FastDFS
    local file_info, err = upload_to_fdfs(form.file);
    if not file_info then
        return nil, err;
    end

    -- save file into to db
    return save_file(form, file_info, share);
end

local function block_upload()
    -- parse form data
    local form, err = parse_form();
    if not form then
        return nil, err;
    end

    local param = form.param;
    local file = form.file;

    -- file size
    local blockSize = file.size;

    local f, err = io.open(file.path, 'rb');
    if not f then
        -- open file err
        return nil, 'open file ' .. file.path .. ' err:' .. err;
    end

    local filedata = f:read('*a');
    f:close();
    f = nil;

    local file_info;
    local uploadedSize;

    if param.appenderFileId then
        local group_name, file_name = utils.split_fileid(param.appenderFileId);

        -- get storage
        local st, err = fdfs.get_storage_update(group_name, file_name);
        if not st then
            return nil, err;
        end

        local res, err = st:append_by_buff(group_name, file_name, filedata);
        st:set_keepalive(0, 5);
        if not res then
            return nil, 'storage upload by buff err: ' .. err;
        end

        file_info = {
            group_name = group_name,
            file_name = file_name
        };

        uploadedSize = param.offset + blockSize;

    else

        -- get storage
        local st, err = fdfs.get_storage();
        if not st then
            return nil, err;
        end

        local res, err = st:upload_appender_by_buff(filedata, param.ext);
        st:set_keepalive(0, 5);
        if not res then
            return nil, 'storage upload by buff err: ' .. err;
        end

        file_info = res;
        uploadedSize = blockSize;
    end

    if uploadedSize < param.fileSize then
        -- return
        return {
            status = 'ok',
            data = {
                appenderFileId = file_info.group_name .. '/' .. file_info.file_name,
                uploadedSize = uploadedSize
            }
        };
    else
        -- check md5
        local url = '/md5sum/' .. file_info.group_name .. '/' .. file_info.file_name;
        local res, err = ngx.location.capture(url, {
            method = ngx.HTTP_POST
        });

        if not res then
            return nil, 'md5sum err: ' .. err;
        end

        if res.body ~= param.fileMd5 then
            return {
                status = 'err_upload_fail',
                msg = 'file md5 err'
            };
        end

        -- save file into to db
        local res_body, err = save_file(form, file_info);

        if not res_body then
            return nil, err;
        end

        -- return
        return {
            status = 'ok',
            data = {
                file = cjson.decode(res_body).data,
                appenderFileId = file_info.group_name .. '/' .. file_info.file_name,
                uploadedSize = uploadedSize
            }
        };
    end

end

return {
    single_upload = single_upload,
    block_upload = block_upload
};