local pDialog = ashita.memory.find('FFXiMain.dll', 0, '908B442404C605????????015068????????E8', 14, 0);
pDialog = ashita.memory.read_uint32(pDialog);

local function GetMenuData()
    local rawString = ashita.memory.read_string(pDialog, 2048):trimend('\x00');
    local question, options = string.match(rawString, "^(.-)\7\11(.*)$")
    local result = { Question=question, Options=T{}};
    for opt in string.gmatch(options, "([^%z\7]+)\7") do
        result.Options:append(opt);
    end
    
    return result;
end

local recorder = {};

function recorder:Reset()
    self.Data = {};
end

function recorder:SaveCategory(index, price)
    local newData = T{ Price=price, Titles=T{}};
    local menu = GetMenuData();
    for titleIndex,option in ipairs(menu.Options) do
        local baseTitle = option;
        if (string.sub(baseTitle, string.len(baseTitle)) == '.') then
            baseTitle = string.sub(baseTitle, 1, string.len(baseTitle)-1);
        end
        newData.Titles[titleIndex-1] = baseTitle;
    end
    self.Data[index] = newData;
end

function recorder:Dump(filename)
    local path = string.format('%saddons/%s/data/%s.lua', AshitaCore:GetInstallPath(), addon.name, filename);
    local out = io.open(path, 'w');
    out:write('return {\n');
    for i = 1,10 do
        local data = self.Data[i];
        if data then
            out:write(string.format('    [%u] = T{\n', i));
            out:write(string.format('        Price = %u,\n', data.Price));
            out:write('        Titles = T{\n');
            for i = 1,28 do
                local title = data.Titles[i] or "N/A";
                out:write(string.format('            [%u] = "%s",\n', i, title));
            end
            out:write('        },\n');
            out:write('    },\n');
        end
    end
    out:write('};');
    out:close();
end

return recorder;