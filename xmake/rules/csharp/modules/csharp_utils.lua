--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, Xmake Open Source Community.
--
-- @author      JassJam
-- @file        csharp_utils.lua
--

-- imports
import("core.project.config")
import("csproj_generator", {alias = "generate_csproj"})

function _is_csharp_target(target)
    if target:rule("csharp") then
        return true
    end
    for _, sourcefile in ipairs(target:sourcefiles()) do
        local ext = path.extension(sourcefile):lower()
        if ext == ".cs" or ext == ".csproj" then
            return true
        end
    end
    return false
end

function _generated_csproj_path(target)
    local targetkey = target:fullname():replace("::", path.sep())
    local csprojdir = path.join(config.directory(), "rules", "csharp", targetkey, target:plat(), target:arch())
    local csprojname = target:name() .. ".csproj"
    return path.join(csprojdir, csprojname)
end

function generate_csproj_file(target)
    if not _is_csharp_target(target) then
        return nil
    end
    local csprojfile = _generated_csproj_path(target)
    generate_csproj(target, csprojfile)
    target:data_set("csharp.csproj", csprojfile)
    return csprojfile
end

