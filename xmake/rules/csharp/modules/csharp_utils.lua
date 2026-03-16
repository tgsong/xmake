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
import("core.base.option")
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

function _map_rid_arch(arch)
    arch = (arch or ""):lower()
    if arch == "x64" or arch == "x86_64" or arch == "amd64" then
        return "x64"
    elseif arch == "x86" or arch == "i386" then
        return "x86"
    elseif arch == "arm64" then
        return "arm64"
    elseif arch == "arm" or arch == "armv7" then
        return "arm"
    elseif arch == "riscv64" then
        return "riscv64"
    end
    return nil
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

function build_mode_to_configuration()
    local mode
    if type(get_config) == "function" then
        mode = get_config("mode")
    end
    if not mode and type(is_mode) == "function" then
        if is_mode("debug") then
            mode = "debug"
        elseif is_mode("release") then
            mode = "release"
        end
    end
    mode = mode or "release"
    local mode_lower = mode:lower()
    if mode_lower == "debug" then
        return "Debug"
    elseif mode_lower == "release" then
        return "Release"
    end
    return mode:sub(1, 1):upper() .. mode:sub(2)
end

function get_runtime_identifier(target)
    local rid = target:values("csharp.runtime_identifier")
    if type(rid) == "table" then
        rid = rid[1]
    end
    if rid and #rid > 0 then
        return rid
    end
    local arch = _map_rid_arch(target:arch())
    if not arch then
        return nil
    end
    local plat = target:plat()
    if plat == "windows" or plat == "mingw" or plat == "msys" or plat == "cygwin" then
        return "win-" .. arch
    elseif plat == "linux" then
        return "linux-" .. arch
    elseif plat == "macosx" then
        return "osx-" .. arch
    end
    return nil
end

