addon.author   = 'Thorny';
addon.name     = 'TitleCheck';
addon.desc     = 'Prints missing titles..';
addon.version  = '1.0';

require ('common');
local chat = require('chat')
local recorder = require('recorder');
local titleSet = T{};
local titleToId = T{};
local titleToNPC = T{};
local playerData = T{
    Titles = T{},
    NPCs = T{},
    Id = 0,
    Name = "",
};
local forceVisible = false;
local printEarned = false;

local function TryLoadFile(filePath)
    if not ashita.fs.exists(filePath) then
        return nil;
    end

    local success, loadError = loadfile(filePath);
    if not success then
        print(string.format('Failed to load resource file: %s', filePath));
        print(loadError);
        return nil;
    end

    local result, output = pcall(success);
    if not result then
        print(string.format('Failed to call resource file: %s', filePath));
        print(output);
        return nil;
    end

    return output;
end

local function LoadAllTitles()
    titleSet = T{};
    local path = string.format('%saddons/%s/data/', AshitaCore:GetInstallPath(), addon.name);
    local contents = ashita.fs.get_directory(path, '.*\\.lua');
    for _,file in pairs(contents) do
        local name = string.sub(file, 1, -5);
        local data = TryLoadFile(path .. file);
        if data then
            titleSet[name] = data;
            for catIndex,catData in pairs(data) do
                for titleIndex, title in pairs(catData.Titles) do
                    local id = titleToId[title];
                    if id then
                        local mapping = titleToNPC[id];
                        if mapping then
                            mapping:append(name);
                        else
                            titleToNPC[id] = T{ name };
                        end
                    end
                end
            end
        end
    end
end

local function SaveCharacterData()
    local outPath = string.format('%sconfig/addons/titlecheck/', AshitaCore:GetInstallPath());
    if not ashita.fs.exists(outPath) then
        ashita.fs.create_directory(outPath);
    end
    local outFile = outPath .. string.format('%s_%u.lua', playerData.Name, playerData.Id);
    if (playerData.Id == 0) or (playerData.Name == '') then
        return;
    end

    local handle = io.open(outFile, 'w');
    handle:write('return T{\n');
    handle:write(string.format('    Name = "%s",\n', playerData.Name));
    handle:write(string.format('    Id = %u,\n', playerData.Id));
    handle:write('    NPCs = T{\n');
    for npc,timestamp in pairs(playerData.NPCs) do
        handle:write(string.format('        ["%s"] = %u,\n', npc, timestamp));
    end
    handle:write('    },\n');
    handle:write('    Titles = T{\n');
    for i = 1,2048 do
        if playerData.Titles[i] ~= nil then
            handle:write(string.format('        [%u] = %s, --%s\n',
            i, playerData.Titles[i] == true and "true" or "false",
            AshitaCore:GetResourceManager():GetString('titles', i):trimend('\x00')));
        end
    end
    handle:write('    },\n');
    handle:write('};');
    handle:close();
end

local function LoadCharacterData(name, id)
    local outPath = string.format('%sconfig/addons/titlecheck/', AshitaCore:GetInstallPath());
    if not ashita.fs.exists(outPath) then
        ashita.fs.create_directory(outPath);
    end
    local outFile = outPath .. string.format('%s_%u.lua', name, id);
    playerData = TryLoadFile(outFile);
    if playerData == nil then
        playerData = T{
            Titles = T{},
            NPCs = T{},
            Name = name,
            Id = id,
        };
        SaveCharacterData();
    end
end

local function DumpTitles()
    --First pass... titles that player is missing
    local outPath = string.format('%sconfig/addons/titlecheck/', AshitaCore:GetInstallPath());
    if not ashita.fs.exists(outPath) then
        ashita.fs.create_directory(outPath);
    end
    outPath = outPath .. string.format('%s_%u.txt', playerData.Name, playerData.Id);

    local outFile = io.open(outPath, 'w');
    local count = 0;
    local outData = T{};
    for i = 1,2048 do
        if playerData.Titles[i] == false then
            outData:append(string.format('%u: %s\n', i, AshitaCore:GetResourceManager():GetString('titles', i):trimend('\x00')));
            count = count + 1;
        end
    end
    outFile:write(string.format('Missing Titles (%u)\n', count));
    for _,line in ipairs(outData) do
        outFile:write(line);
    end
    
    --Second pass... titles that player knows..
    count = 0;
    outData = T{};
    for i = 1,2048 do
        if playerData.Titles[i] == true then
            outData:append(string.format('%u: %s\n', i, AshitaCore:GetResourceManager():GetString('titles', i):trimend('\x00')));
            count = count + 1;
        end
    end
    
    outFile:write(string.format('\nKnown Titles (%u)\n', count));
    for _,line in ipairs(outData) do
        outFile:write(line);
    end

    --Third pass... titles that aren't registered yet for the character
    count = 0;
    outData = T{};
    local missingNPCs = T{};
    for i = 1,2048 do
        if (playerData.Titles[i] == nil) and (titleToNPC[i] ~= nil) then
            for _,npc in ipairs(titleToNPC[i]) do
                missingNPCs[npc] = true;
            end
            
            count = count + 1;
            outData:append(string.format('%u: %s\n', i, AshitaCore:GetResourceManager():GetString('titles', i):trimend('\x00')));
        end
    end
    local sorted = T{};
    for npc,_ in pairs(missingNPCs) do
        sorted:append(npc);
    end
    table.sort(sorted);

    
    outFile:write(string.format('\nMissing Title Data (%u)\n', count));
    for _,line in ipairs(outData) do
        outFile:write(line);
    end

    if #sorted > 0 then
        outFile:write('\nMissing title data is available at the following NPCs:\n');
        print('Title data may be incomplete. Missing titles available at the following NPCs:');
        for _,npc in ipairs(sorted) do
            print(npc);
            outFile:write(npc .. '\n');
        end
    end

    outFile:close();
end

ashita.events.register('load', 'TitleCheck_load', function()
    for i = 1,2048 do
        local res = AshitaCore:GetResourceManager():GetString('titles', i);
        if res then
            titleToId[res:trimend('\x00')] = i;
        end
    end
    LoadAllTitles();

    if AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0) ~= 0 then
        LoadCharacterData(AshitaCore:GetMemoryManager():GetParty():GetMemberName(0), AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0));
    end
end);

ashita.events.register('command', 'TitleCheck_HandleCommand', function (e)
    local args = e.command:args();
    if (args[1] == '/tr') then
        if (args[2] == 'forcevisible') then
            forceVisible = not forceVisible;
            print(string.format('Force Title Visibility: %s', forceVisible and "Enabled" or "Disabled"));
        end
        
        if (args[2] == 'reset') then
            recorder:Reset();
            print('Reset recorder.');
        end

        if (args[2] == 'record') then
            recorder:SaveCategory(tonumber(args[3]), tonumber(args[4]));
            print(string.format('Recorded titles (Index %u, Price %u).', tonumber(args[3]), tonumber(args[4])));
        end

        if (args[2] == 'dump') then
            local targetMgr = AshitaCore:GetMemoryManager():GetTarget();
            local targetIndex = targetMgr:GetTargetIndex(targetMgr:GetIsSubTargetActive());
            local name = AshitaCore:GetMemoryManager():GetEntity():GetName(targetIndex);
            recorder:Dump(name);
            print(string.format('Saved titles to: %s.lua', name));
        end
        
        e.blocked = true;
        return;
    end

    if (args[1] == '/title') then

        if (args[2] == 'dump') then
            DumpTitles();
        end

        e.blocked = true;
        return;
    end
end);

ashita.events.register('packet_in', 'titlecheck_HandleIncomingPacket', function (e)
    if (e.id == 0x00A) then
        local id = struct.unpack('L', e.data, 0x04 + 1);
        local name = struct.unpack('c16', e.data, 0x84 + 1):trimend('\x00');

        if (id ~= playerData.Id) or (name ~= playerData.Name) then
            LoadCharacterData(name, id);
        end
    end

    if (e.id == 0x033) then
        if (forceVisible) then
            for category = 1,6 do
                ashita.bits.pack_be(e.data_modified_raw, 0, 0x4C + (category *4), 0, 32);
            end
        end
        
        local entityIndex = struct.unpack('H', e.data, 0x08+1);
        local entityName = AshitaCore:GetMemoryManager():GetEntity():GetName(entityIndex);
        local titleData = titleSet[entityName];
        if titleData then
            local utc_time_table = os.date("!*t");
            local utc_timestamp = os.time(utc_time_table);
            playerData.NPCs[entityName] = utc_timestamp;
            for category = 1,6 do
                local titleSet = titleData[category];
                if titleSet then
                    local data = struct.unpack('L', e.data, 0x4C + (category*4) + 1);
                    for index = 1,28 do
                        local hasTitle = (bit.band(data, bit.lshift(1, index)) == 0)
                        local title = titleSet.Titles[index];
                        if title and title ~= 'N/A' then
                            if hasTitle then
                                if printEarned then
                                    print(chat.color1(2, string.format('%s: Earned', title)));
                                end
                            else
                                print(chat.color1(68, string.format('%s: Not Earned', title)));
                            end

                            local id = titleToId[title];
                            if id then
                                playerData.Titles[id] = hasTitle;
                            end
                        end
                    end
                end
            end
            SaveCharacterData();
        end
    end
end);