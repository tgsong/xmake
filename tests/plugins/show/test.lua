import("core.base.json")

function test_depgraph_json(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph", "--json"})
    local graph = json.decode(outdata)

    t:are_equal(graph.root_targets, {"app"})
    t:require(#graph.targets == 3)

    local entries = {}
    for _, target in ipairs(graph.targets) do
        entries[target.name] = target
    end
    t:are_equal(entries.core.deps, {})
    t:are_equal(entries.ui.deps, {"core"})
    t:are_equal(entries.app.deps, {"core", "ui"})
end

function test_depgraph_json_for_single_target(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph", "--target=app", "--json"})
    local graph = json.decode(outdata)

    t:are_equal(graph.root_targets, {"app"})
    t:require(#graph.targets == 3)

    local names = {}
    for _, target in ipairs(graph.targets) do
        table.insert(names, target.name)
    end
    t:are_equal(names, {"core", "ui", "app"})
end

function test_depgraph_tree(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph"})
    t:require(outdata:find("app", 1, true))
    t:require(outdata:find("core", 1, true))
    t:require(outdata:find("ui", 1, true))
    t:require(outdata:find("|-- ", 1, true))
    t:require(outdata:find("\\-- ", 1, true))
end

function test_depgraph_dot(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph", "--dot"})
    t:require(outdata:find("digraph {", 1, true))
    t:require(outdata:find('"core"', 1, true))
    t:require(outdata:find('"ui" -> "core"', 1, true))
    t:require(outdata:find('"app" -> "core"', 1, true))
    t:require(outdata:find('"app" -> "ui"', 1, true))
    t:require(outdata:find("}", 1, true))
end

function test_depgraph_dot_for_single_target(t)
    local outdata = os.iorunv("xmake", {"show", "--info=depgraph", "--target=ui", "--dot"})
    t:require(outdata:find("digraph {", 1, true))
    t:require(outdata:find('"core"', 1, true))
    t:require(outdata:find('"ui" -> "core"', 1, true))
    t:require(not outdata:find('"app"', 1, true))
end
