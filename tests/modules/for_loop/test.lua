-- Regression tests for Lua 5.4 for-loop customizations in xmake:
--   1. RDKCONST is relaxed on the control variable (parser patch), so
--      reassigning `i` in a numeric-for or `k` in a generic-for compiles.
--   2. Sandbox `pairs` snapshots keys so reassigning the first loop
--      variable cannot corrupt the iterator state — otherwise `next`
--      would later fail with "invalid key to 'next'".

function test_numeric_for_reassign(t)
    -- Just needs to compile & run without "attempt to assign to const".
    local sum = 0
    for i = 1, 5 do
        i = i * 10
        sum = sum + i
    end
    t:require(sum == 10 + 20 + 30 + 40 + 50)
end

function test_generic_for_reassign_key(t)
    local tbl = {foo_a = 1, foo_b = 2, foo_c = 3}
    local seen = {}
    local count = 0
    for k, v in pairs(tbl) do
        k = k:gsub("_", "-")
        seen[k] = v
        count = count + 1
    end
    t:require(count == 3)
    t:require(seen["foo-a"] == 1)
    t:require(seen["foo-b"] == 2)
    t:require(seen["foo-c"] == 3)
end

function test_generic_for_reassign_many_keys(t)
    -- Stress the snapshot path with enough keys that a broken iterator
    -- would deterministically trip `next` on the second iteration.
    local tbl = {}
    for i = 1, 64 do
        tbl["key_" .. i] = i
    end
    local total = 0
    for name, value in pairs(tbl) do
        name = name:gsub("_", "-")  -- would corrupt `next`'s key arg
        t:require(name:find("^key%-%d+$") ~= nil)
        total = total + value
    end
    t:require(total == (1 + 64) * 64 / 2)
end

function test_list_items_reassign(t)
    import("core.base.list")
    local l = list.new()
    for i = 1, 5 do
        l:push({name = "n" .. i})
    end
    local names = {}
    for item in l:items() do
        item = nil  -- would corrupt list:next on the next iteration
        -- re-fetch to prove we don't rely on `item`
    end
    local count = 0
    for item in l:items() do
        count = count + 1
        table.insert(names, item.name)
    end
    t:require(count == 5)
    t:require(names[1] == "n1" and names[5] == "n5")
end

function test_irpairs_reassign_index(t)
    local arr = {"a", "b", "c", "d", "e"}
    local collected = {}
    for i, v in irpairs(arr) do
        i = -1  -- would corrupt the index on the next iteration
        table.insert(collected, v)
    end
    t:require(#collected == 5)
    t:require(collected[1] == "e")
    t:require(collected[5] == "a")
end

function test_hashset_items_reassign(t)
    import("core.base.hashset")
    local set = hashset.from({"key_1", "key_2", "key_3", "key_4", "key_5"})
    local seen = {}
    for item in set:items() do
        item = item:gsub("_", "-")  -- would corrupt `next`'s key arg
        seen[item] = true
    end
    local count = 0
    for _ in pairs(seen) do count = count + 1 end
    t:require(count == 5)
    for i = 1, 5 do
        t:require(seen["key-" .. i] == true)
    end
end

function test_ipairs_reassign_index(t)
    -- With the stock Lua 5.4 `ipairs`, writing to the first loop variable
    -- would silently shift the index on the next iteration (no error,
    -- just wrong results). Sandbox `ipairs` hides the counter in an
    -- upvalue so the body's write is harmless.
    local list = {10, 20, 30, 40, 50}
    local seen = {}
    for i, v in ipairs(list) do
        i = -1  -- would corrupt iteration if `i` were the control slot
        table.insert(seen, v)
    end
    t:require(#seen == 5)
    for idx = 1, 5 do
        t:require(seen[idx] == list[idx])
    end
end

function test_generic_for_reassign_value(t)
    -- Writing to the second loop variable is always safe (it isn't the
    -- iterator control), but exercise it anyway to pin the behavior.
    local tbl = {a = 1, b = 2, c = 3}
    local total = 0
    for _, v in pairs(tbl) do
        v = v * 2
        total = total + v
    end
    t:require(total == 12)
end
