---@meta

---@class table
table = table

---@param list table
---@param comparator fun(a: any, b: any): boolean
function table.insertion_sort(list, comparator) end

---@param list table
---@param comparator fun(a: any, b: any): boolean
function table.stable_sort(list, comparator) end

---@param list table
---@param comparator fun(a: any, b: any): boolean
function table.unstable_sort(list, comparator) end
