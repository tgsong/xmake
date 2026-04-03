inherit(".test_base")

local PRIVATE_DEFINE = "PRIVATE_DEP_DEFINE_DO_NOT_PROPAGATE"
local PUBLIC_SYSINCLUDEDIR = path.translate(path.absolute("src/include"))

function _build()
    local outdata = os.iorun("xmake -r -vD")
    local leaked = false
    local missing_sysincludedir = true
    for line in outdata:gmatch("[^\r\n]+") do
        if line:find("Consumer", 1, true) then
            if line:find(PRIVATE_DEFINE, 1, true) then
                leaked = true
            end
            if line:find(PUBLIC_SYSINCLUDEDIR, 1, true) then
                missing_sysincludedir = false
            end
        end
    end
    if leaked then
        raise("Private dependency defines leaked into Consumer module rebuilds under reuse.strict\n%s", outdata)
    end
    if missing_sysincludedir then
        raise("Missing public sysincludedir in Consumer module rebuilds under reuse.strict\n%s", outdata)
    end
    os.run("xmake -vD")
end

function main(_)
    local clang_options = {compiler = "clang", version = CLANG_MIN_VER, build = _build}
    local gcc_options = {compiler = "gcc", version = GCC_MIN_VER, build = _build}
    local msvc_options = {version = MSVC_MIN_VER, build = _build}
    run_tests(clang_options, gcc_options, msvc_options)
end
