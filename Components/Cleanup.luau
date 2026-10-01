local Cleanup = {
    Items = {}
}

function Cleanup:Add(Item)
    table.insert(self.Items, Item)
    return Item
end

function Cleanup:Connect(Signal, Callback)
    return self:Add(Signal:Connect(Callback))
end

function Cleanup:Run()
    for Index = #self.Items, 1, -1 do
        local Item = self.Items[Index]
        pcall(function()
            local Kind = typeof(Item)
            if Kind == "RBXScriptConnection" then
                Item:Disconnect()
            elseif Kind == "Instance" then
                Item:Destroy()
            elseif Kind == "function" then
                Item()
            elseif Kind == "table" and Item.Destroy then
                Item:Destroy()
            end
        end)
    end
    table.clear(self.Items)
end

return Cleanup
