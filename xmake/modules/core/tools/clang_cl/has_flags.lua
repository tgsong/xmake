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
-- @author      ruki
-- @file        has_flags.lua
--

-- imports
import("core.cache.detectcache")
import("core.language.language")
import("core.base.hashset")

-- attempt to check it from known flags
function _check_from_knownargs(flags, opt)
    local flag = flags[1]:gsub("/", "-")
    local known_flags = _g.known_flags
    if known_flags == nil then
        known_flags = hashset.from({
            "-Ox", "-O1", "-O2", "-Od",
            "-MT", "-MD", "-MTd", "-MDd",
            "-EHsc", "-EHa", "-EHs",
            "-W0", "-W1", "-W2", "-W3", "-W4", "-Wall", "-WX",
            "-Z7", "-Zi", "-ZI",
            "-c", "-nologo", "-FS", "-FC", "-Gm-",
            "-GR", "-GR-", "-GS", "-GS-",
            "-Gy", "-Gy-", "-GL",
            "-Gd", "-Gr", "-Gz", "-Gv",
            "-TC", "-TP",
            "-utf-8", "-bigobj", "-MP",
            "-showIncludes"
        })
        _g.known_flags = known_flags
    end
    if known_flags:has(flag) then
        return true
    end
    -- check flags with known prefixes that always accept values (all versions)
    if flag:startswith("-D") or
       flag:startswith("-U") or
       flag:startswith("-I") or
       flag:startswith("-Fo") or
       flag:startswith("-Fe") or
       flag:startswith("-Fd") or
       flag:startswith("-FI") or
       flag:startswith("-wd") or
       flag:startswith("-we") or
       flag:startswith("-wo") then
        return true
    end
end

-- attempt to check it from the argument list
function _check_from_arglist(flags, opt)

    -- only one flag?
    if #flags > 1 then
        return
    end

    -- make cache key
    local key = "core.tools.clang_cl.has_flags"

    -- make allflags key
    local flagskey = opt.program .. "_" .. (opt.programver or "")

    -- get all allflags from argument list
    local allflags = detectcache:get2(key, flagskey)
    if not allflags then

        -- get argument list
        allflags = {}
        local arglist = os.iorunv(opt.program, {"-?"})
        if arglist then
            for arg in arglist:gmatch("(/[%-%a%d]+)%s+") do
                allflags[arg:gsub("/", "-")] = true
            end
        end

        -- save cache
        detectcache:set2(key, flagskey, allflags)
    end
    return allflags[flags[1]:gsub("/", "-")]
end

-- try running
function _try_running(...)

    local argv = {...}
    local errors = nil
    return try { function () os.runv(table.unpack(argv)); return true end, catch { function (errs) errors = (errs or ""):trim() end }}, errors
end

-- try running to check flags
function _check_try_running(flags, opt)

    -- get extension
    -- @note we need to detect extension for ndk/clang++.exe: warning: treating 'c' input as 'c++' when in C++ mode, this behavior is deprecated [-Wdeprecated]
    local extension = opt.program:endswith("++") and ".cpp" or (table.wrap(language.sourcekinds()[opt.toolkind or "cc"])[1] or ".c")

    -- make an stub source file
    local sourcefile = path.join(os.tmpdir(), "detect", "clang_cl_has_flags" .. extension)
    if not os.isfile(sourcefile) then
        io.writefile(sourcefile, "int main(int argc, char** argv)\n{return 0;}\n")
    end

    -- check flags for compiler
    -- @note we cannot use os.nuldev() as the output file, maybe run failed for some flags, e.g. --coverage
    return _try_running(opt.program, table.join("-Werror=unused-command-line-argument", flags, "-c", "-o", os.tmpfile(), sourcefile))
end

-- has_flags(flags)?
--
-- @param opt   the argument options, e.g. {toolname = "", program = "", programver = "", toolkind = "[cc|cxx|ld|ar|sh|gc|rc|dc|mm|mxx]"}
--
-- @return      true or false
--
function main(flags, opt)

    -- attempt to check it from known flags
    opt = opt or {}
    if _check_from_knownargs(flags, opt) then
        return true
    end

    -- attempt to check it from the argument list
    if _check_from_arglist(flags, opt) then
        return true
    end

    -- try running to check it
    return _check_try_running(flags, opt)
end

