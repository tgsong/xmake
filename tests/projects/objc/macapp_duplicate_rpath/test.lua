function main(t)
    if not is_host("macosx") then
        return t:skip("wrong host platform")
    end

    local homedir = path.absolute("home")
    os.setenv("HOME", homedir)
    os.mkdir(homedir)
    os.mkdir(path.join(homedir, ".xmake"))

    local xmake = path.absolute(path.join(os.projectdir(), "build", "xmake"))
    local xmake_program_dir = path.absolute(path.join(os.projectdir(), "xmake"))
    os.setenv("XMAKE_PROGRAM_FILE", xmake)
    os.setenv("XMAKE_PROGRAM_DIR", xmake_program_dir)

    os.execv(xmake, {"f", "-p", "macosx", "-a", os.arch(), "-c"})
    os.execv(xmake, {"-vD"})
end
