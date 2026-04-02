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
-- @file        xmake.lua
--

toolchain("filc")
    set_kind("standalone")
    set_homepage("https://fil-c.org/")
    set_description("A memory safe implementation of the C and C++ programming languages.")

    on_check(function (toolchain)
        import("lib.detect.find_tool")

        -- look in package installdir/build/bin and bin first, then bindir/sdkdir, then PATH
        local paths = {}
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir then
                table.insert(paths, path.join(installdir, "build", "bin"))
                table.insert(paths, path.join(installdir, "bin"))
            end
        end
        local bindir = toolchain:bindir()
        if bindir then
            table.insert(paths, bindir)
        end
        local sdkdir = toolchain:sdkdir()
        if sdkdir then
            table.insert(paths, path.join(sdkdir, "build", "bin"))
            table.insert(paths, path.join(sdkdir, "bin"))
        end

        local filcc = find_tool("filcc", {paths = paths, force = true})
        if filcc then
            toolchain:config_set("filcc", filcc.program)
            if os.isfile(filcc.program) then
                toolchain:config_set("bindir", path.directory(filcc.program))
            end
            -- discover fil++ explicitly rather than inferring from filcc's bindir
            local filxx = find_tool("fil++", {paths = paths, force = true})
            if filxx then
                toolchain:config_set("filxx", filxx.program)
            end
            return true
        end
    end)

    on_load(function (toolchain)
        local filcc = toolchain:config("filcc") or "filcc"
        local filpp = toolchain:config("filxx") or (function()
            local bindir = toolchain:config("bindir")
            return bindir and path.join(bindir, "fil++") or "fil++"
        end)()

        -- filcc/fil++ are the compilers and linker; ar uses the system archiver
        toolchain:set("toolset", "cc",  filcc)
        toolchain:set("toolset", "cxx", filpp)
        toolchain:set("toolset", "ld",  filcc)
        toolchain:set("toolset", "sh",  filcc)
        toolchain:set("toolset", "ar",  "ar")
        toolchain:set("toolset", "as",  filcc)

        -- expose host system headers (GL, X11, etc.) via -idirafter so they are
        -- searched AFTER filc's own libc++ headers, preventing stdlib.h conflicts
        for _, sysdir in ipairs({"/usr/include", "/usr/local/include"}) do
            if os.isdir(sysdir) then
                toolchain:add("cflags",  "-idirafter", sysdir)
                toolchain:add("cxflags", "-idirafter", sysdir)
            end
        end

        -- add runtime include/lib dirs from the installed package or sdk
        local function _add_pizfix(dir)
            local pizfix = path.join(dir, "pizfix")
            -- only add stdfil-include for stdfil.h; pizfix/include (musl C headers)
            -- must NOT be added as -isystem or it breaks libc++'s stdlib.h include order
            local stdfil_include = path.join(pizfix, "stdfil-include")
            if os.isdir(stdfil_include) then
                toolchain:add("sysincludedirs", stdfil_include)
            end
            for _, libdir in ipairs({path.join(pizfix, "lib64"), path.join(pizfix, "lib")}) do
                if os.isdir(libdir) then
                    toolchain:add("linkdirs", libdir)
                end
            end
        end
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir then
                _add_pizfix(installdir)
            end
        end
        local sdkdir = toolchain:sdkdir()
        if sdkdir and os.isdir(sdkdir) then
            _add_pizfix(sdkdir)
        end
    end)
