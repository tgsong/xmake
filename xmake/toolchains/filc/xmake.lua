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

        -- look in package installdir/build/bin first, then bindir/sdkdir, then PATH
        local paths = {}
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir then
                table.insert(paths, path.join(installdir, "build", "bin"))
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
            return true
        end
    end)

    on_load(function (toolchain)
        local filcc = toolchain:config("filcc") or "filcc"

        -- filcc is the compiler and linker; ar uses the system archiver
        toolchain:set("toolset", "cc",  filcc)
        toolchain:set("toolset", "ld",  filcc)
        toolchain:set("toolset", "sh",  filcc)
        toolchain:set("toolset", "ar",  "ar")
        toolchain:set("toolset", "as",  filcc)

        -- add runtime include/lib dirs from the installed package
        for _, package in ipairs(toolchain:packages()) do
            local installdir = package:installdir()
            if installdir then
                local pizfix = path.join(installdir, "pizfix")
                -- stdfil.h lives in pizfix/stdfil-include/
                toolchain:add("sysincludedirs", path.join(pizfix, "stdfil-include"))
                -- standard C headers (musl-based) live in pizfix/include/
                toolchain:add("sysincludedirs", path.join(pizfix, "include"))
                toolchain:add("linkdirs",       path.join(pizfix, "lib"))
                toolchain:add("linkdirs",       path.join(pizfix, "lib64"))
            end
        end
        local sdkdir = toolchain:sdkdir()
        if sdkdir and os.isdir(sdkdir) then
            local pizfix = path.join(sdkdir, "pizfix")
            for _, d in ipairs({"stdfil-include", "include"}) do
                local includedir = path.join(pizfix, d)
                if os.isdir(includedir) then
                    toolchain:add("sysincludedirs", includedir)
                end
            end
            for _, libdir in ipairs({path.join(pizfix, "lib64"), path.join(pizfix, "lib")}) do
                if os.isdir(libdir) then
                    toolchain:add("linkdirs", libdir)
                end
            end
        end
    end)
