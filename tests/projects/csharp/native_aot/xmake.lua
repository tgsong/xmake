add_rules("mode.debug", "mode.release")

target("cslib")
    set_kind("shared")
    add_files("src/cslib/*.cs")
    set_values("csharp.publish_aot", "true")

target("app")
    set_kind("binary")
    add_deps("cslib")
    add_files("src/app/*.cpp")
