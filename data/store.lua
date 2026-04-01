local love = require("love")

local Store = {}

local tasks = {}
local nextId = 1013 -- default seed data goes up to TASK-1012

local SAVE_FILE = "tasks.lua"

function Store.load()
    local ok, chunk = pcall(love.filesystem.load, SAVE_FILE)
    if ok and chunk then
        local ok2, data = pcall(chunk)
        if ok2 and type(data) == "table" then
            -- Extract nextId metadata
            if data._nextId then
                nextId = data._nextId
                data._nextId = nil
            end
            -- Remove non-numeric keys
            tasks = {}
            for i, task in ipairs(data) do
                tasks[i] = task
            end
            return
        end
    end
    -- Fall back to seed data
    local defaults = require("data.tasks")
    tasks = {}
    for i, task in ipairs(defaults) do
        tasks[i] = {
            id = task.id,
            label = task.label,
            title = task.title,
            description = task.description,
            status = task.status,
            priority = task.priority,
        }
    end
end

function Store.save()
    local parts = { "return {\n" }
    parts[#parts + 1] = "  _nextId = " .. nextId .. ",\n"
    for _, task in ipairs(tasks) do
        parts[#parts + 1] = "  {\n"
        parts[#parts + 1] = "    id = " .. string.format("%q", task.id) .. ",\n"
        parts[#parts + 1] = "    label = " .. string.format("%q", task.label) .. ",\n"
        parts[#parts + 1] = "    title = " .. string.format("%q", task.title) .. ",\n"
        parts[#parts + 1] = "    description = " .. string.format("%q", task.description) .. ",\n"
        parts[#parts + 1] = "    status = " .. string.format("%q", task.status) .. ",\n"
        parts[#parts + 1] = "    priority = " .. string.format("%q", task.priority) .. ",\n"
        parts[#parts + 1] = "  },\n"
    end
    parts[#parts + 1] = "}\n"
    love.filesystem.write(SAVE_FILE, table.concat(parts))
end

function Store.getTasks()
    return tasks
end

function Store.nextId()
    local id = string.format("TASK-%04d", nextId)
    nextId = nextId + 1
    return id
end

function Store.addTask(task)
    task.id = task.id or Store.nextId()
    tasks[#tasks + 1] = task
    Store.save()
    return task
end

function Store.updateTask(id, changes)
    for _, task in ipairs(tasks) do
        if task.id == id then
            for k, v in pairs(changes) do
                task[k] = v
            end
            Store.save()
            return task
        end
    end
    return nil
end

function Store.deleteTask(id)
    for i, task in ipairs(tasks) do
        if task.id == id then
            table.remove(tasks, i)
            Store.save()
            return true
        end
    end
    return false
end

function Store.copyTask(id)
    for _, task in ipairs(tasks) do
        if task.id == id then
            local copy = {
                id = Store.nextId(),
                label = task.label,
                title = task.title .. " (copy)",
                description = task.description,
                status = task.status,
                priority = task.priority,
            }
            tasks[#tasks + 1] = copy
            Store.save()
            return copy
        end
    end
    return nil
end

return Store
