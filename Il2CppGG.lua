--Module: Il2CppGG v1.0.5 (Patched)
--Author: LeThi9GG / Fixed
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("Il2CppGG", function(require, _LOADED, __bundle_register, __bundle_modules)
---@module Il2Cpp
Il2Cpp = function(config)
    local _path, config = package.path, config or {}
    package.path = gg.getFile():match("(.*[/%\\])") .. "?.lua;" .. package.path;
    
    ---Main initialization module for Il2Cpp framework
    Il2Cpp = require "core.Il2Cpp"()
    
    package.path = _path
    
    Il2Cpp.log.level = config.log or Il2Cpp.log.level
    
    -- Setup global metadata and Il2Cpp registration
    Il2Cpp.log:info("Initializing il2cpp ...")
    local il2cppStart, il2cppEnd = config.il2cppStart, config.il2cppEnd
    if not il2cppStart and not il2cppEnd then
        il2cppStart, il2cppEnd = Il2Cpp.Searcher.FindIl2cpp()
    end
    Il2Cpp.il2cppStart = il2cppStart
    Il2Cpp.il2cppEnd = il2cppEnd
    
    Il2Cpp.log:info("Il2Cpp Version: " .. Il2Cpp.Version)
    Il2Cpp.log:info("Il2Cpp Start Address: " .. Il2Cpp.ToHex(Il2Cpp.il2cppStart))
    
    Il2Cpp.log:info("Initializing metadata...")
    local metaStart, metaEnd = config.metaStart, config.metaEnd
    if not metaStart and not metaEnd then
        metaStart, metaEnd = Il2Cpp.Searcher:FindGlobalMetaData()
    end
    Il2Cpp.Searcher:Il2CppMetadataRegistration(metaStart)
    Il2Cpp.Meta.metaStart = metaStart
    Il2Cpp.Meta.metaEnd = metaEnd
    Il2Cpp.Meta(metaStart, Il2Cpp.Version)
    Il2Cpp.log:info("Metadata Version: " .. Il2Cpp.Meta.Version)
    Il2Cpp.log:info("Metadata Start Address: " .. Il2Cpp.ToHex(metaStart))
    
    local il2cppStart, il2cppEnd = Il2Cpp.Searcher.FindIl2cpp(Il2Cpp.metaReg)
    Il2Cpp.il2cppStart = il2cppStart
    Il2Cpp.il2cppEnd = il2cppEnd
    
    Il2Cpp.log:info("Change Il2Cpp Start Address to: " .. Il2Cpp.ToHex(Il2Cpp.il2cppStart))
    
    -- Calculate type size and initialize Type module properties
    Il2Cpp.Type.typeCount = Il2Cpp.typeCount
    Il2Cpp.Type.type = Il2Cpp.pMetadataRegistration.types
    
    return Il2Cpp
end

end)
__bundle_register("core.Il2Cpp", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class Il2Cpp
---Main Il2Cpp module providing core functionality and type definitions
local AndroidInfo = require "utils.Androidinfo"
local x64 = AndroidInfo.platform
local pointer = x64 and gg.TYPE_QWORD or gg.TYPE_DWORD
local MainType = pointer
local pointSize = x64 and 8 or 4
local Struct = require "core.Struct"
local Version = require "core.Version"
local Config = require "config"

function table.toDictionary(array, keySelector)
    local dict = {}
    for _, item in ipairs(array) do
        dict[keySelector(item)] = item
    end
    return dict
end

function table.all(array, predicate)
    for _, item in ipairs(array) do
        if not predicate(item) then
            return false
        end
    end
    return true
end

Il2Cpp = {
    x64 = x64,
    armType = x64 and 6 or 4,
    pointer = pointer,
    MainType = MainType,
    pointSize = pointSize,
    methodSpecGenericMethodPointers = {},
    methodDefinitionMethodSpecs = {},
    genericMethodPointers = {},
    Info = AndroidInfo,
    
    __cache = {
        Class = {},
        Field = {},
        Method = {},
        Param = {},
        Type = {},
        Utf8ToString = {}
    }
}

Il2Cpp.type = {
    Boolean = { size = 1, flags = 1 },
    Byte    = { size = 1, flags = 1 },
    SByte   = { size = 1, flags = 1 },
    Int8    = { size = 1, flags = 1 },
    UInt8   = { size = 1, flags = 1 },
    Int16   = { size = 2, flags = 2 },
    UInt16  = { size = 2, flags = 2 },
    Int32   = { size = 4, flags = 4 },
    UInt32  = { size = 4, flags = 4 },
    Int64   = { size = 8, flags = 32 },
    UInt64  = { size = 8, flags = 32 },
    Float   = { size = 4, flags = 16 },
    Double  = { size = 8, flags = 64 },
    Pointer = { size = pointSize, flags = pointer },
    Size_t  = { size = pointSize, flags = pointer },
    Object = { size = (Il2Cpp.x64 and 0x10 or 0x8), flags = pointer}
}

Il2Cpp.TypeFlag = {
    [2] = 1,
    [4] = 1,
    [5] = 1,
    [6] = 2,
    [7] = 2,
    [8] = 4,
    [9] = 4,
    [12] = 16,
    [13] = 64,
}

function Il2Cpp.GetTypeToFlags(types)
    if types == 2 then 
        menu_item = 1
    elseif types >= 4 and 9 <= types then 
        menu_item = 2 
    elseif types == 12 then 
        menu_item = 3
    elseif types == 13 then 
        menu_item = 4
    else 
        menu_item = 5 
    end
end

function Il2Cpp.ToHex(number)
    return string.format("%X", number or 0)
end

function Il2Cpp.GetPtr(address)
    if not address or address == 0 then return 0 end
    local res = gg.getValues({{address = Il2Cpp.FixValue(address), flags = Il2Cpp.MainType}})
    if not res or not res[1] then return 0 end
    return Il2Cpp.FixValue(res[1].value)
end

function Il2Cpp.FixValue(val)
	return (x64 and ((val or 0) & 0x00FFFFFFFFFFFFFF)) or ((val or 0) & 0xFFFFFFFF);
end

function Il2Cpp.gV(address, flags)
    if not address then return 0 end
	return (type(address) == "table" and gg.getValues(address)) or gg.getValues({{address=address,flags=flags or Il2Cpp.MainType}})[1].value;
end

function Il2Cpp.aL(address, name, flags)
	return (type(address) == "table" and gg.addListItems(address)) or gg.addListItems({{address=address,flags=flags or Il2Cpp.MainType, name = name}})
end

function Il2Cpp.align(offset, align_to)
    return math.floor((offset + align_to - 1) / align_to) * align_to
end

Il2Cpp.Utf8ToString = function(Address, length)
    if not Address or Address == 0 then return "" end
    if not length and Il2Cpp.__cache.Utf8ToString[Address] then
        return Il2Cpp.__cache.Utf8ToString[Address]
    end
    local chars, char = {}, {
        address = Address,
        flags = gg.TYPE_BYTE
    }
    if not length then
        while true do
            local vals = gg.getValues({char})
            if not vals or not vals[1] then break end
            local _char = string.char(vals[1].value & 0xFF)
            chars[#chars + 1] = _char
            char.address = char.address + 0x1
            if string.find(_char, "[%z%s]") then break end
        end
        local Text = table.concat(chars, "", 1, #chars - 1)
        Il2Cpp.__cache.Utf8ToString[Address] = Text
        return Text
    else
        for i = 1, length do
            local vals = gg.getValues({char})
            if not vals or not vals[1] then break end
            local _char = vals[1].value
            chars[i] = string.char(_char & 0xFF)
            char.address = char.address + 0x1
        end
        local Text = table.concat(chars)
        return Text
    end
end

function Il2Cpp.classArray(addr, count, class)
    local results = {}
    if Il2Cpp.type[class] then
        class = Il2Cpp.type[class]
    end
    for i = 0, count - 1 do
        table.insert(results, class.flags and {address = addr + (i * class.size), flags = class.flags} or class(addr + (i * class.size)))
    end
    if class.flags then
        for i, v in ipairs(gg.getValues(results)) do
            results[i] = v.value
        end
    end
    return results
end

function Il2Cpp.classGG(fields, version) 
    local offset = 0
    local klass = {}
    for _, field in ipairs(fields) do
        local includeField = true
        if field.version then
            local v = field.version
            if (v and #v == 0) and (version < (v.min or 0) or version > (v.max or 99)) then
                includeField = false
            elseif v and #v > 0 then
                for _, attr in ipairs(v) do
                    if (version < (attr.min or 0) or version > (attr.max or 99)) then
                        includeField = false
                    end
                end
            end
        end
        if includeField then
            local fieldInfo = {
                name = field[1],
                type = field[2]
            }
            if type(fieldInfo.type) == "table" and not fieldInfo.type.size then
                fieldInfo.type = Il2Cpp.classGG(fieldInfo.type, version)
            end
            local tInfo = Il2Cpp.type[fieldInfo.type]
            
            offset = Il2Cpp.align(offset, 
                math.min(tInfo and tInfo.size or fieldInfo.type.size, Il2Cpp.pointSize)
            )
            if not tInfo then
                klass[fieldInfo.name] = fieldInfo.type
                fieldInfo.type.address = offset
                offset = offset + fieldInfo.type.size
            else
                klass[#klass+1] = {
                    address = offset,
                    flags = tInfo.flags,
                    type = fieldInfo.type,
                    name = fieldInfo.name
                }
                offset = offset + tInfo.size
            end
        end
    end
    klass.size = offset
    klass.GetSize = function(self)
        return self.size 
    end
    return setmetatable(klass, {
        __call = function(self, addr, addList, prefix)
            Il2Cpp.log:debug(fields.name .. ":", addr)
			dataRes, t, prefix = {}, {}, prefix or ''
            for i, v in pairs(self) do
                if type(v) == "table" then
                    if v.size then
                        t[i] = v(v.address + addr, addList, prefix .. i .. ".")
                    else
                        local address = v.address + addr
                        dataRes[#dataRes+1] = {address = address, flags = v.flags, name = prefix .. v.name}
                    end
                end
            end
            fields.AddList = function(self, name)
                local nameList, list = (name or self.name) .. ":\n", {}
                for i, v in ipairs(dataRes) do 
                    list[i] = {address = v.address, flags = v.flags, name = nameList .. v.name}
                end
                Il2Cpp.aL(list)
                return dataRes
            end
            if addList then 
                Il2Cpp.aL(dataRes)
            end
            for i, v in ipairs(gg.getValues(dataRes)) do 
                t[self[i].name] = self[i].type == "Pointer" and Il2Cpp.FixValue(v.value) or v.value
                if v.flags == Il2Cpp.pointer and (self[i].name == "name" or self[i].name == "namespaze") then
                    t[self[i].name] = Il2Cpp.Utf8ToString(t[self[i].name])
                end
            end
            return setmetatable(t, {
                __index = fields,
                __name = fields.name
            })
        end
    })
end

Il2Cpp.Il2CppFlags = {
    Method = {
        METHOD_ATTRIBUTE_MEMBER_ACCESS_MASK = 0x0007,
        Access = { "private", "internal", "internal", "protected", "protected internal", "public" },
        METHOD_ATTRIBUTE_STATIC = 0x0010,
        METHOD_ATTRIBUTE_ABSTRACT = 0x0400,
    },
    Field = {
        FIELD_ATTRIBUTE_FIELD_ACCESS_MASK = 0x0007,
        Access = { "private", "internal", "internal", "protected", "protected internal", "public" },
        FIELD_ATTRIBUTE_STATIC = 0x0010,
        FIELD_ATTRIBUTE_LITERAL = 0x0040,
    }
}

Il2Cpp.Il2CppTypeEnum = {
    IL2CPP_TYPE_END = 0x00,
    IL2CPP_TYPE_VOID = 0x01,
    IL2CPP_TYPE_BOOLEAN = 0x02,
    IL2CPP_TYPE_CHAR = 0x03,
    IL2CPP_TYPE_I1 = 0x04,
    IL2CPP_TYPE_U1 = 0x05,
    IL2CPP_TYPE_I2 = 0x06,
    IL2CPP_TYPE_U2 = 0x07,
    IL2CPP_TYPE_I4 = 0x08,
    IL2CPP_TYPE_U4 = 0x09,
    IL2CPP_TYPE_I8 = 0x0a,
    IL2CPP_TYPE_U8 = 0x0b,
    IL2CPP_TYPE_R4 = 0x0c,
    IL2CPP_TYPE_R8 = 0x0d,
    IL2CPP_TYPE_STRING = 0x0e,
    IL2CPP_TYPE_PTR = 0x0f,
    IL2Cpp_TYPE_BYREF = 0x10,
    IL2CPP_TYPE_VALUETYPE = 0x11,
    IL2CPP_TYPE_CLASS = 0x12,
    IL2CPP_TYPE_VAR = 0x13,
    IL2CPP_TYPE_ARRAY = 0x14,
    IL2CPP_TYPE_GENERICINST = 0x15,
    IL2CPP_TYPE_TYPEDBYREF = 0x16,
    IL2CPP_TYPE_I = 0x18,
    IL2CPP_TYPE_U = 0x19,
    IL2CPP_TYPE_FNPTR = 0x1b,
    IL2CPP_TYPE_OBJECT = 0x1c,
    IL2CPP_TYPE_SZARRAY = 0x1d,
    IL2CPP_TYPE_MVAR = 0x1e,
    IL2CPP_TYPE_CMOD_REQD = 0x1f,
    IL2CPP_TYPE_CMOD_OPT = 0x20,
    IL2CPP_TYPE_INTERNAL = 0x21,
    IL2CPP_TYPE_MODIFIER = 0x40,
    IL2CPP_TYPE_SENTINEL = 0x41,
    IL2CPP_TYPE_PINNED = 0x45,
    IL2CPP_TYPE_ENUM = 0x55,
    IL2CPP_TYPE_IL2CPP_TYPE_INDEX = 0xff,
}

Il2Cpp.Il2CppConstants = {
    FIELD_ATTRIBUTE_FIELD_ACCESS_MASK = 0x0007,
    FIELD_ATTRIBUTE_COMPILER_CONTROLLED = 0x0000,
    FIELD_ATTRIBUTE_PRIVATE = 0x0001,
    FIELD_ATTRIBUTE_FAM_AND_ASSEM = 0x0002,
    FIELD_ATTRIBUTE_ASSEMBLY = 0x0003,
    FIELD_ATTRIBUTE_FAMILY = 0x0004,
    FIELD_ATTRIBUTE_FAM_OR_ASSEM = 0x0005,
    FIELD_ATTRIBUTE_PUBLIC = 0x0006,
    FIELD_ATTRIBUTE_STATIC = 0x0010,
    FIELD_ATTRIBUTE_INIT_ONLY = 0x0020,
    FIELD_ATTRIBUTE_LITERAL = 0x0040,

    METHOD_ATTRIBUTE_MEMBER_ACCESS_MASK = 0x0007,
    METHOD_ATTRIBUTE_COMPILER_CONTROLLED = 0x0000,
    METHOD_ATTRIBUTE_PRIVATE = 0x0001,
    METHOD_ATTRIBUTE_FAM_AND_ASSEM = 0x0002,
    METHOD_ATTRIBUTE_ASSEM = 0x0003,
    METHOD_ATTRIBUTE_FAMILY = 0x0004,
    METHOD_ATTRIBUTE_FAM_OR_ASSEM = 0x0005,
    METHOD_ATTRIBUTE_PUBLIC = 0x0006,
    METHOD_ATTRIBUTE_STATIC = 0x0010,
    METHOD_ATTRIBUTE_FINAL = 0x0020,
    METHOD_ATTRIBUTE_VIRTUAL = 0x0040,
    METHOD_ATTRIBUTE_VTABLE_LAYOUT_MASK = 0x0100,
    METHOD_ATTRIBUTE_REUSE_SLOT = 0x0000,
    METHOD_ATTRIBUTE_NEW_SLOT = 0x0100,
    METHOD_ATTRIBUTE_ABSTRACT = 0x0400,
    METHOD_ATTRIBUTE_PINVOKE_IMPL = 0x2000,

    TYPE_ATTRIBUTE_VISIBILITY_MASK = 0x00000007,
    TYPE_ATTRIBUTE_NOT_PUBLIC = 0x00000000,
    TYPE_ATTRIBUTE_PUBLIC = 0x00000001,
    TYPE_ATTRIBUTE_NESTED_PUBLIC = 0x00000002,
    TYPE_ATTRIBUTE_NESTED_PRIVATE = 0x00000003,
    TYPE_ATTRIBUTE_NESTED_FAMILY = 0x00000004,
    TYPE_ATTRIBUTE_NESTED_ASSEMBLY = 0x00000005,
    TYPE_ATTRIBUTE_NESTED_FAM_AND_ASSEM = 0x00000006,
    TYPE_ATTRIBUTE_NESTED_FAM_OR_ASSEM = 0x00000007,
    TYPE_ATTRIBUTE_INTERFACE = 0x00000020,
    TYPE_ATTRIBUTE_ABSTRACT = 0x00000080,
    TYPE_ATTRIBUTE_SEALED = 0x00000100,
    TYPE_ATTRIBUTE_SERIALIZABLE = 0x00002000,

    PARAM_ATTRIBUTE_IN = 0x0001,
    PARAM_ATTRIBUTE_OUT = 0x0002,
    PARAM_ATTRIBUTE_OPTIONAL = 0x0010,
}

Il2Cpp.methodModifiers = {}
function Il2Cpp:GetModifiers(methodDef)
    if self.methodModifiers[methodDef] then
        return self.methodModifiers[methodDef]
    end
    local str = ""
    local access = bit32.band(methodDef.flags, Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_MEMBER_ACCESS_MASK)
    if access == Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_PRIVATE then
        str = str .. "private "
    elseif access == Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_PUBLIC then
        str = str .. "public "
    elseif access == Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_FAMILY then
        str = str .. "protected "
    elseif access == Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_ASSEM or access == Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_FAM_AND_ASSEM then
        str = str .. "internal "
    elseif access == Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_FAM_OR_ASSEM then
        str = str .. "protected internal "
    end
    if bit32.band(methodDef.flags, Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_STATIC) ~= 0 then
        str = str .. "static "
    end
    if bit32.band(methodDef.flags, Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_ABSTRACT) ~= 0 then
        str = str .. "abstract "
        if bit32.band(methodDef.flags, Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_VTABLE_LAYOUT_MASK) == Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_REUSE_SLOT then
            str = str .. "override "
        end
    elseif bit32.band(methodDef.flags, Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_FINAL) ~= 0 then
        if bit32.band(methodDef.flags, Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_VTABLE_LAYOUT_MASK) == Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_REUSE_SLOT then
            str = str .. "sealed override "
        end
    elseif bit32.band(methodDef.flags, Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_VIRTUAL) ~= 0 then
        if bit32.band(methodDef.flags, Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_VTABLE_LAYOUT_MASK) == Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_NEW_SLOT then
            str = str .. "virtual "
        else
            str = str .. "override "
        end
    end
    if bit32.band(methodDef.flags, Il2Cpp.Il2CppConstants.METHOD_ATTRIBUTE_PINVOKE_IMPL) ~= 0 then
        str = str .. "extern "
    end
    self.methodModifiers[methodDef] = str
    return str
end

function Il2Cpp.searchPtr(...)
    local config = {...}
    gg.clearResults();
    gg.searchNumber(...);
    
    if gg.getResultsCount() == 0 and AndroidInfo.platform and AndroidInfo.sdk >= 30 then
        local addrs = config[1]
        table.remove(config, 1)
        gg.searchNumber(tostring(addrs | 0xB400000000000000), table.unpack(config));
    end
    
    local t = gg.getResults(gg.getResultsCount())
    if #t > 0 then
        gg.clearResults();
        return t
    end
    error(string.format("Không tìm thấy con trỏ tại địa chỉ: 0x%X", config[1]))
end

function Il2Cpp:Developer(config, list, result)
    if config.addList or config.log then 
        local nameList, list = {"End", "Start", "Def", "Reg", "Count", "Size", "Ptr", "ersion"}, list or self
        local results = result or {}
        for key, value in pairs(list) do 
            if type(value) == "number" then
                for i, v in ipairs(nameList) do
                    if key:find(".*" .. v) then
                        if config.log then 
                            Il2Cpp.log:info(key, value)
                        end
                        local name = key .. ((v == "Count" or v == "Size" or v == "ersion") and (": " .. value) or "")
                        local flags = (v == "End" or v == "Start") and gg.TYPE_DWORD or Il2Cpp.MainType
                        local value = v == "End" and value - 1 or value
                        results[#results+1] = {address = value, name = name, flags = flags}
                    end
                end
            elseif key == "Meta" then
                self:Developer(config, value, results)
            end
        end
        if not result and config.addList then
           gg.addListItems(results)
        end
        return results
    elseif config.setUp then
        for key, value in pairs(config.setUp) do
            self[key] = value
        end
        return self
    end
end

Il2Cpp.log = {
    results = {},
    level = {},
    name = Config.name,
    debug = function(self, ...)
        if self.level.DEBUG then 
            self:log(string.format(self.name .. ": [%s] " ..  ..., "Debug"))
        end 
    end,
    warn = function(self, ...)
        if self.level.WARN or self.level.INFO or self.level.DEBUG then 
            self:log(string.format(self.name .. ": [%s] " ..  ..., "Warn"))
        end 
    end,
    info = function(self, ...)
        if self.level.WARN or self.level.INFO or self.level.DEBUG then 
            self:log(string.format(self.name .. ": [%s] " ..  ..., "Info"))
        end 
    end,
    error = function(self, ...)
        local message = string.format(self.name .. ": [%s] " ..  ..., "Error")
        self:log(message)
        gg.alert(message)
        error(message)
    end,
    log = function(self, ...)
        print(...)
        gg.toast(...)
        table.insert(self.results, ...)
    end
}

function Il2Cpp:Dumper(config, target, callback)
    local target = target or {}
    if not target.path then 
        local info = gg.getTargetInfo()
        target.path = gg.EXT_STORAGE .. "/" .. info.packageName .. "-" .. info.versionCode .. "-" .. (info.x64 and "64" or "32") .. ".cs"
    end
    local config = config or {
        DumpAttribute = false,
        DumpField = true,
        DumpProperty = true,
        DumpMethod = true,
        DumpFieldOffset = true,
        DumpMethodOffset = true,
        DumpTypeDefIndex = false,
    }
    self.log:info("Path: " .. target.path)
    
    local output = io.open(target.path, "w")
    local startTime = os.time();
    local imageDefs = target.image or self.Image()
    for i, imageDef in ipairs(imageDefs) do
        output:write(string.format("// Image %d: %s - %d\n", i - 1, imageDef:GetName(), imageDef.typeStart))
    end

    for _, imageDef in ipairs(imageDefs) do
        local imageName = imageDef:GetName()
        local typeEnd = imageDef.typeStart + imageDef.typeCount
        for typeDefIndex = imageDef.typeStart, typeEnd do
            if callback and gg.isClickedUiButton() then
                local message = "[" .. imageName .. "]: " .. typeEnd - typeDefIndex .. "/" .. typeEnd
                if callback(message) and gg.alert("Dumper Interrupted:\n\n- Done: " .. typeDefIndex .. "/" .. typeEnd .. " Class.\n- Continue?\n", "Ok", "", "Exit") == 3 then
                    break
                end
            end
            output:write(self.Class(typeDefIndex):Dump(config) .. "\n")
        end
    end
    output:close()
    local dumpTimeDiff = os.time() - startTime;
	self.log:info(string.format("Dumper Done in %.2f seconds", dumpTimeDiff));
    return target.path
end

function Il2Cpp:searchName(searchParams, config)
    local config = config or {}
    local searchParams = type(searchParams) == "table" and searchParams or (config.Api and self.Meta:GetPointersToStringApi(searchParams) or self.Meta.GetPointersToString(searchParams))
    local results = {}
    if config.Class then
        results.Class = self.Class(searchParams) or {}
        results.Class = results.Class.address and {results.Class} or results.Class
        function results.Class:AddList(self)
            local result = {}
            for i, v in ipairs(results.Class) do
                result[i] = {address = v.address, flags = Il2Cpp.MainType, name = v:Dump()}
            end
            Il2Cpp.aL(result)
            return result
        end
    end
    if config.Fields then
        results.Fields = self.Field(searchParams) or {}
        results.Fields = results.Fields.address and {results.Fields} or results.Fields
        function results.Fields:AddList(self)
            local result = {}
            for i, v in ipairs(results.Fields) do               
                local className = "class: " .. v:GetParent():GetName()
                table.insert(result, {address = v.address, flags = Il2Cpp.MainType, name = className .. "\n" .. v:ToString()})
            end
            Il2Cpp.aL(result)
            return result
        end
    end
    if config.Methods then
        results.Methods = self.Method(searchParams) or {}
        results.Methods = results.Methods.address and {results.Methods} or results.Methods
        function results.Methods:AddList(self)
            local result = {}
            for i, v in ipairs(results.Methods) do
                local className = "class: " .. v:GetClass():GetName()
                result[i] = {address = v.address, flags = Il2Cpp.MainType, name = className .. "\n" .. v:ToString()}
            end
            Il2Cpp.aL(result)
            return result
        end
    end
    function results:AddList(self)
        if results.Class then
            results.Class:AddList()
        end
        if results.Fields then
            results.Fields:AddList()
        end
        if results.Methods then
            results.Methods:AddList()
        end
    end
    return results
end

return setmetatable(Struct, {
    __call = function(self)
        Il2Cpp.Version = Version()
        local default = Il2Cpp.Version
        
        if default == 22 then
          default = 22
        elseif default == 23 or default == 24 then
          default = 24.0
        elseif default == 24.1 then
          default = 24.1
        elseif default == 24.2 or default == 24.3 or default == 24.4 or default == 24.5 then
          default = 24.2
        elseif default == 27 or default == 27.1 or default == 27.2 then
          default = 27
        elseif default == 29 then
          default = 29
        elseif default == 31 or default == 29.1 then
            default = 29.1
        end
        Il2Cpp._Version = default
        Il2Cpp._Il2CppMethodDefinition = self.Il2CppMethodDefinition
        Il2Cpp._Il2CppGlobalMetadataHeader = self.Il2CppGlobalMetadataHeader
        for k, v in pairs(self) do
            v.name = k
            Il2Cpp[k] = Il2Cpp.classGG(v, default)
        end
      
        local api = {
            Patch = require "utils.Patch",
            Meta = require "core.Meta",
            Searcher = require "core.Universalsearcher",
            Class = require "api.Class",
            Field = require "api.Field",
            Method = require "api.Method",
            Param = require "api.Param",
            Object = require "api.Object",
            Image = require "api.Image",
            Type = require "api.Type"
        }
        
        return setmetatable(api, {
            __index = Il2Cpp
        })
    end
})

end)
__bundle_register("utils.Androidinfo", function(require, _LOADED, __bundle_register, __bundle_modules)
local info = gg.getTargetInfo()
local AndroidInfo = {
    platform = info.x64,
    sdk = info.targetSdkVersion,
    pkg = gg.getTargetPackage(),
    name = info.name,
    targetInfo = info,
    path = gg.EXT_CACHE_DIR .. "/" .. info.packageName + "-" .. info.versionCode + "-" .. (info.x64 and "64" or "32")
}
return AndroidInfo
end)
__bundle_register("core.Struct", function(require, _LOADED, __bundle_register, __bundle_modules)
local Structs = {
    Il2CppGlobalMetadataHeader = {
        { "sanity", "UInt32"},
        { "version", "Int32" },
        { "stringLiteralOffset", "UInt32" },
        { "stringLiteralSize", "Int32" },
        { "stringLiteralDataOffset", "UInt32" },
        { "stringLiteralDataSize", "Int32" },
        { "stringOffset", "UInt32" },
        { "stringSize", "Int32" },
        { "eventsOffset", "UInt32" },
        { "eventsSize", "Int32" },
        { "propertiesOffset", "UInt32" },
        { "propertiesSize", "Int32" },
        { "methodsOffset", "UInt32" },
        { "methodsSize", "Int32" },
        { "parameterDefaultValuesOffset", "UInt32" },
        { "parameterDefaultValuesSize", "Int32" },
        { "fieldDefaultValuesOffset", "UInt32" },
        { "fieldDefaultValuesSize", "Int32" },
        { "fieldAndParameterDefaultValueDataOffset", "UInt32" },
        { "fieldAndParameterDefaultValueDataSize", "Int32" },
        { "fieldMarshaledSizesOffset", "UInt32" },
        { "fieldMarshaledSizesSize", "Int32" },
        { "parametersOffset", "UInt32" },
        { "parametersSize", "Int32" },
        { "fieldsOffset", "UInt32" },
        { "fieldsSize", "Int32" },
        { "genericParametersOffset", "UInt32" },
        { "genericParametersSize", "Int32" },
        { "genericParameterConstraintsOffset", "UInt32" },
        { "genericParameterConstraintsSize", "Int32" },
        { "genericContainersOffset", "UInt32" },
        { "genericContainersSize", "Int32" },
        { "nestedTypesOffset", "UInt32" },
        { "nestedTypesSize", "Int32" },
        { "interfacesOffset", "UInt32" },
        { "interfacesSize", "Int32" },
        { "vtableMethodsOffset", "UInt32" },
        { "vtableMethodsSize", "Int32" },
        { "interfaceOffsetsOffset", "UInt32" },
        { "interfaceOffsetsSize", "Int32" },
        { "typeDefinitionsOffset", "UInt32" },
        { "typeDefinitionsSize", "Int32" },
        { "rgctxEntriesOffset", "UInt32", version = {max = 24.1} },
        { "rgctxEntriesCount", "Int32", version = {max = 24.1} },
        { "imagesOffset", "UInt32" },
        { "imagesSize", "Int32" },
        { "assembliesOffset", "UInt32" },
        { "assembliesSize", "Int32" },
        { "metadataUsageListsOffset", "UInt32", version = {min = 19, max = 24.5} },
        { "metadataUsageListsCount", "Int32", version = {min = 19, max = 24.5} },
        { "metadataUsagePairsOffset", "UInt32", version = {min = 19, max = 24.5} },
        { "metadataUsagePairsCount", "Int32", version = {min = 19, max = 24.5} },
        { "fieldRefsOffset", "UInt32", version = {min = 19} },
        { "fieldRefsSize", "Int32", version = {min = 19} },
        { "referencedAssembliesOffset", "UInt32", version = {min = 20} },
        { "referencedAssembliesSize", "Int32", version = {min = 20} },
        { "attributesInfoOffset", "UInt32", version = {min = 21, max = 27.2} },
        { "attributesInfoCount", "Int32", version = {min = 21, max = 27.2} },
        { "attributeTypesOffset", "UInt32", version = {min = 21, max = 27.2} },
        { "attributeTypesCount", "Int32", version = {min = 21, max = 27.2} },
        { "attributeDataOffset", "UInt32", version = {min = 29} },
        { "attributeDataSize", "Int32", version = {min = 29} },
        { "attributeDataRangeOffset", "UInt32", version = {min = 29} },
        { "attributeDataRangeSize", "Int32", version = {min = 29} },
        { "unresolvedVirtualCallParameterTypesOffset", "UInt32", version = {min = 22} },
        { "unresolvedVirtualCallParameterTypesSize", "Int32", version = {min = 22} },
        { "unresolvedVirtualCallParameterRangesOffset", "UInt32", version = {min = 22} },
        { "unresolvedVirtualCallParameterRangesSize", "Int32", version = {min = 22} },
        { "windowsRuntimeTypeNamesOffset", "UInt32", version = {min = 23} },
        { "windowsRuntimeTypeNamesSize", "Int32", version = {min = 23} },
        { "windowsRuntimeStringsOffset", "UInt32", version = {min = 27} },
        { "windowsRuntimeStringsSize", "Int32", version = {min = 27} },
        { "exportedTypeDefinitionsOffset", "UInt32", version = {min = 24} },
        { "exportedTypeDefinitionsSize", "Int32", version = {min = 24} },
    },
    
    Il2CppMetadataRegistration = {
        { "genericClassesCount", "Pointer" },
        { "genericClasses", "Pointer" },
        { "genericInstsCount", "Pointer" },
        { "genericInsts", "Pointer" },
        { "genericMethodTableCount", "Pointer" },
        { "genericMethodTable", "Pointer" },
        { "typesCount", "Pointer" },
        { "types", "Pointer" },
        { "methodSpecsCount", "Pointer" },
        { "methodSpecs", "Pointer" },
        { "methodReferencesCount", "Pointer", version = { max = 16 } },
        { "methodReferences", "Pointer", version = { max = 16 } },
        { "fieldOffsetsCount", "Pointer" },
        { "fieldOffsets", "Pointer" },
        { "typeDefinitionsSizesCount", "Pointer" },
        { "typeDefinitionsSizes", "Pointer" },
        { "metadataUsagesCount", "Pointer", version = { min = 19 } },
        { "metadataUsages", "Pointer", version = { min = 19 } }
    },
    
    Il2CppCodeRegistration = {
        { "methodPointersCount", "Pointer", version = { max = 24.1} },
        { "methodPointers", "Pointer", version = { max = 24.1} },
        { "delegateWrappersFromNativeToManagedCount", "Pointer", version = { max = 21}},
        { "delegateWrappersFromNativeToManaged", "Pointer", version = { max = 21} },
        { "reversePInvokeWrapperCount", "Pointer", version = { min = 22}},
        { "reversePInvokeWrappers", "Pointer", version = { min = 22}},
        { "delegateWrappersFromManagedToNativeCount", "Pointer", version = { max = 22} },
        { "delegateWrappersFromManagedToNative", "Pointer", version = { max = 22} },
        { "marshalingFunctionsCount", "Pointer", version = { max = 22} },
        { "marshalingFunctions", "Pointer", version = { max = 22} },
        { "ccwMarshalingFunctionsCount", "Pointer", version = { min = 21, max = 22} },
        { "ccwMarshalingFunctions", "Pointer", version = { min = 21, max = 22} },
        { "genericMethodPointersCount", "Pointer" },
        { "genericMethodPointers", "Pointer" },
        { "genericAdjustorThunks", "Pointer", version = {{ min = 24.5, max = 24.5}, { min = 27.1}} },
        { "invokerPointersCount", "Pointer" },
        { "invokerPointers", "Pointer" },
        { "customAttributeCount", "Pointer", version = { max = 24.5}},
        { "customAttributeGenerators", "Pointer", version = { max = 24.5}},
        { "guidCount", "Pointer", version = { min = 21, max = 22}},
        { "guids", "Pointer", version = { min = 21, max = 22}},
        { "unresolvedVirtualCallCount", "Pointer", version = { min = 22}},
        { "unresolvedVirtualCallPointers", "Pointer", version = { min = 22}},
        { "unresolvedInstanceCallPointers", "Pointer", version = { min = 29.1} },
        { "unresolvedStaticCallPointers", "Pointer", version = { min = 29.1} },
        { "interopDataCount", "Pointer", version = { min = 23} },
        { "interopData", "Pointer", version = { min = 23}},
        { "windowsRuntimeFactoryCount", "Pointer", version = { min = 24.3}},
        { "windowsRuntimeFactoryTable", "Pointer", version = { min = 24.3} },
        { "codeGenModulesCount", "Pointer", version = { min = 24.2 }},
        { "codeGenModules", "Pointer", version = { min = 24.2 } }
    },
    
    Il2CppTypeDefinition = {
        { "nameIndex", "UInt32" },
        { "namespaceIndex", "UInt32" },
        { "customAttributeIndex", "Int32", version = { max = 24}},
        { "byvalTypeIndex", "Int32" },
        { "byrefTypeIndex", "Int32", version = { max = 24.5} },
        { "declaringTypeIndex", "Int32" },
        { "parentIndex", "Int32" },
        { "elementTypeIndex", "Int32" },
        { "rgctxStartIndex", "Int32", version = { max = 24.1} },
        { "rgctxCount", "Int32", version = { max = 24.1} },
        { "genericContainerIndex", "Int32" },
        { "delegateWrapperFromManagedToNativeIndex", "Int32", version = { max = 22} },
        { "marshalingFunctionsIndex", "Int32", version = { max = 22 }},
        { "ccwFunctionIndex", "Int32", version = { min = 21, max = 22} },
        { "guidIndex", "Int32", version = { min = 21, max = 22} },
        { "flags", "UInt32" },
        { "fieldStart", "Int32" },
        { "methodStart", "Int32" },
        { "eventStart", "Int32" },
        { "propertyStart", "Int32" },
        { "nestedTypesStart", "Int32" },
        { "interfacesStart", "Int32" },
        { "vtableStart", "Int32" },
        { "interfaceOffsetsStart", "Int32" },
        { "method_count", "UInt16" },
        { "property_count", "UInt16" },
        { "field_count", "UInt16" },
        { "event_count", "UInt16" },
        { "nested_type_count", "UInt16" },
        { "vtable_count", "UInt16" },
        { "interfaces_count", "UInt16" },
        { "interface_offsets_count", "UInt16" },
        { "bitfield", "UInt32" },
        { "token", "UInt32", version = { min = 19 } },
        
        IsValueType = function(this) return bit32.band(this.bitfield, 0x1) == 1 end,
        IsEnum = function(this) return bit32.band(bit32.rshift(this.bitfield, 1), 0x1) == 1 end
    },

    VirtualInvokeData = {
        { "methodPtr", "Pointer" },
        { "method", "Pointer" }
    },

    Il2CppType = {
        { "data", "Pointer" },
        { "bits", "UInt32" },
        Init = function(self)
            self.attrs = bit32.band(self.bits, 0xffff)
            self.type = bit32.rshift(bit32.band(self.bits, 0xff0000), 16)
            if Il2Cpp.Version >= 27.2 then
                self.num_mods = bit32.band(bit32.rshift(self.bits, 24), 0x1f)
                self.byref = bit32.band(bit32.rshift(self.bits, 29), 1)
                self.pinned = bit32.band(bit32.rshift(self.bits, 30), 1)
                self.valuetype = bit32.rshift(self.bits, 31)
            else
                self.num_mods = bit32.band(bit32.rshift(self.bits, 24), 0x3f)
                self.byref = bit32.band(bit32.rshift(self.bits, 30), 1)
                self.pinned = bit32.rshift(self.bits, 31)
            end
            return self
        end
    },
    
    Il2CppObject = {
        { "klass", "Pointer" },
        { "monitor", "Pointer" }
    },

    Il2CppRGCTXData = {
        { "rgctxDataDummy", "Pointer" }
    },

    Il2CppRuntimeInterfaceOffsetPair = {
        { "interfaceType", "Pointer" },
        { "offset", "Int32" }
    },

    FieldInfo = {
        { "name", "Pointer" },
        { "type", "Pointer" },
        { "parent", "Pointer" },
        { "offset", "Int32" },
        { "token", "UInt32" }
    },

    Il2CppArrayBounds = {
        { "length", "Int32", version = { max = 24.0 } },
        { "length", "Size_t", version = { min = 24.1 } },
        { "lower_bound", "Int32" }
    }
}

Structs.Il2CppClass = {
    { "image", "Pointer" },
    { "gc_desc", "Pointer" },
    { "name", "Pointer"},
    { "namespaze", "Pointer" },
    { "byval_arg", "Pointer", version = { max = 24.0 } },
    { "byval_arg", Structs.Il2CppType, version = { min = 24.1 } },
    { "this_arg", "Pointer", version = { max = 24.0 } },
    { "this_arg", Structs.Il2CppType, version = { min = 24.1 } },
    { "element_class", "Pointer" },
    { "castClass", "Pointer" },
    { "declaringType", "Pointer" },
    { "parent", "Pointer" },
    { "generic_class", "Pointer" },
    { "typeDefinition", "Pointer", version = { min = 24.1, max = 24.5 } },
    { "typeMetadataHandle", "Pointer", version = { min = 27 } },
    { "interopData", "Pointer" },
    { "klass", "Pointer", version = { min = 24.1 } },
    { "fields", "Pointer" },
    { "events", "Pointer" },
    { "properties", "Pointer" },
    { "methods", "Pointer" },
    { "nestedTypes", "Pointer" },
    { "implementedInterfaces", "Pointer" },
    { "interfaceOffsets", "Pointer" },
    { "static_fields", "Pointer" },
    { "rgctx_data", "Pointer" },
    { "typeHierarchy", "Pointer" },
    { "unity_user_data", "Pointer", version = { min = 24.2 } },
    { "initializationExceptionGCHandle", "UInt32", version = { min = 24.1 } },
    { "cctor_started", "UInt32" },
    { "cctor_finished", "UInt32" },
    { "cctor_thread", "UInt64", version = { max = 24.1 } },
    { "cctor_thread", "Size_t", version = { min = 24.2 } },
    { "genericContainerIndex", "Int32", version = { max = 24.5 } },
    { "genericContainerHandle", "Pointer", version = { min = 27 } },
    { "customAttributeIndex", "Int32", version = { max = 24.0 } },
    { "instance_size", "UInt32" },
    { "stack_slot_size", "UInt32" , version = { min = 29.1 } },
    { "actualSize", "UInt32" },
    { "element_size", "UInt32" },
    { "native_size", "Int32" },
    { "static_fields_size", "UInt32" },
    { "thread_static_fields_size", "UInt32" },
    { "thread_static_fields_offset", "Int32" },
    { "flags", "UInt32" },
    { "token", "UInt32" },
    { "method_count", "UInt16" },
    { "property_count", "UInt16" },
    { "field_count", "UInt16" },
    { "event_count", "UInt16" },
    { "nested_type_count", "UInt16" },
    { "vtable_count", "UInt16" },
    { "interfaces_count", "UInt16" },
    { "interface_offsets_count", "UInt16" },
    { "typeHierarchyDepth", "UInt8" },
    { "genericRecursionDepth", "UInt8" },
    { "rank", "UInt8" },
    { "minimumAlignment", "UInt8" },
    { "naturalAligment", "UInt8" },
    { "packingSize", "UInt8" },
    { "bitflags1", "UInt8" },
    { "bitflags2", "UInt8" }
}

Structs.MethodInfo = {
    { "methodPointer", "Pointer" },
    { "virtualMethodPointer", "Pointer", version = { min = 29 } },
    { "invoker_method", "Pointer" },
    { "name", "Pointer" },
    { "klass", "Pointer", version = { min = 24.1 } },
    { "declaring_type", "Pointer", version = { max = 24.0 } },
    { "return_type", "Pointer" },
    { "parameters", "Pointer" },
    { "methodDefinition", "Pointer", version = { max = 24.5 } },
    { "genericContainer", "Pointer", version = { max = 24.5 } },
    { "methodMetadataHandle", "Pointer", version = { min = 27 } },
    { "genericContainerHandle", "Pointer", version = { min = 27 } },
    { "customAttributeIndex", "Int32", version = { max = 24.0 } },
    { "token", "UInt32" },
    { "flags", "UInt16" },
    { "iflags", "UInt16" },
    { "slot", "UInt16" },
    { "parameters_count", "UInt8" },
    { "bitflags", "UInt8" }
}

Structs.PropertyInfo = {
    { "parent", "Pointer" },
    { "name", "Pointer" },
    { "get", "Pointer" },
    { "set", "Pointer" },
    { "attrs", "UInt32" },
    { "token", "UInt32" }
}

Structs.Il2CppPropertyDefinitionDef = {
    { "nameIndex", "UInt32"},
    { "get", "Int32"},
    { "set", "Int32"},
    { "attrs", "UInt32"},
    { "customAttributeIndex", "Int32", version = {max = 24}},
    { "token", "UInt32", version = {min = 19}}
}

Structs.Il2CppGenericContext = {
    { "class_inst", "Pointer"},
    { "method_inst", "Pointer"},
}

Structs.Il2CppGenericClass = {
    { "typeDefinitionIndex", "Pointer", version = {max = 24.5}},
    { "type", "Pointer", version = {min = 27}},
    { "context", Structs.Il2CppGenericContext},
    { "cached_class", "Pointer"},
}

Structs.Il2CppGenericInst = {
    { "type_argc", "Pointer"},
    { "type_argv", "Pointer"},
}

Structs.Il2CppArrayType = {
    { "etype", "Pointer"},
    { "rank", "Int8"},
    { "numsizes", "Int8"},
    { "numlobounds", "Int8"},
    { "sizes", "Pointer"},
    { "lobounds", "Pointer"},
}

Structs.Il2CppGenericParameter = {
    { "ownerIndex", "Int32" },
    { "nameIndex", "UInt32" },
    { "constraintsStart", "Int16" },
    { "constraintsCount", "Int16" },
    { "num", "UInt16" },
    { "flags", "UInt16" }
}

Structs.Il2CppGenericContainer = {
    { "ownerIndex", "Int32" },
    { "type_argc", "Int32" },
    { "is_method", "Int32" },
    { "genericParameterStart", "Int32" }
}

Structs.Il2CppMethodDefinition = {
    { "nameIndex", "UInt32" },
    { "declaringType", "Int32" },
    { "returnType", "Int32" },
    { "returnParameterToken", "Int32", version = {min = 31} },
    { "parameterStart", "Int32" },
    { "customAttributeIndex", "Int32", version = {max = 24} },
    { "genericContainerIndex", "Int32" },
    { "methodIndex", "Int32", version = {max = 24.1} },
    { "invokerIndex", "Int32", version = {max = 24.1} },
    { "delegateWrapperIndex", "Int32", version = {max = 24.1} },
    { "rgctxStartIndex", "Int32", version = {max = 24.1} },
    { "rgctxCount", "Int32", version = {max = 24.1} },
    { "token", "UInt32" },
    { "flags", "UInt16" },
    { "iflags", "UInt16" },
    { "slot", "UInt16" },
    { "parameterCount", "UInt16" }
}

Structs.Il2CppParameterDefinition = {
    { "nameIndex", "UInt32" },
    { "token", "UInt32" },
    { "customAttributeIndex", "Int32", version = {max = 24} },
    { "typeIndex", "Int32" }
}

Structs.Il2CppGenericMethodIndices = {
    { "methodIndex", "Int32" },
    { "invokerIndex", "Int32" },
    { "adjustorThunk", "Int32", version = {{ min = 24.5, max = 24.5 }, { min = 27.1 }} }
}

Structs.Il2CppGenericMethodFunctionsDefinitions = {
    { "genericMethodIndex", "Int32" },
    { "indices", Structs.Il2CppGenericMethodIndices }
}

Structs.Il2CppMethodSpec = {
    { "methodDefinitionIndex", "Int32" },
    { "classIndexIndex", "Int32" },
    { "methodIndexIndex", "Int32" }
}

Structs.Il2CppParameterDefaultValue = {
    { "parameterIndex", "Int32" },
    { "typeIndex", "Int32" },
    { "dataIndex", "Int32" }
}

Structs.Il2CppFieldDefaultValue = {
    { "fieldIndex", "Int32" },
    { "typeIndex", "Int32" },
    { "dataIndex", "Int32" }
}

return Structs
end)
__bundle_register("core.Version", function(require, _LOADED, __bundle_register, __bundle_modules)
local function compareVersions(v1, v2)
    if v1.major ~= v2.major then
        return v1.major < v2.major and -1 or 1
    end
    if v1.minor ~= v2.minor then
        return v1.minor < v2.minor and -1 or 1
    end
    if v1.patch ~= v2.patch then
        return v1.patch < v2.patch and -1 or 1
    end
    return 0
end

local osUV = 0x11

local VersionEngine = {
    ConstSemVer = {
        ['2018_3'] = { major = 2018, minor = 3, patch = 0 },
        ['2019_4_21'] = { major = 2019, minor = 4, patch = 21 },
        ['2019_4_15'] = { major = 2019, minor = 4, patch = 15 },
        ['2019_3_7'] = { major = 2019, minor = 3, patch = 7 },
        ['2020_2_4'] = { major = 2020, minor = 2, patch = 4 },
        ['2020_2'] = { major = 2020, minor = 2, patch = 0 },
        ['2020_1_11'] = { major = 2020, minor = 1, patch = 11 },
        ['2021_2'] = { major = 2021, minor = 2, patch = 0 },
        ['2022_2'] = { major = 2022, minor = 2, patch = 0 },
        ['2022_3_41'] = { major = 2022, minor = 3, patch = 41 },
    },
    
    Year = {
        [2017] = function(self, unityVersion) return 24 end,
        [2018] = function(self, unityVersion)
            return compareVersions(unityVersion, self.ConstSemVer['2018_3']) >= 0 and 24.1 or 24
        end,
        [2019] = function(self, unityVersion)
            local version = 24.2
            if compareVersions(unityVersion, self.ConstSemVer['2019_4_21']) >= 0 then
                version = 24.5
            elseif compareVersions(unityVersion, self.ConstSemVer['2019_4_15']) >= 0 then
                version = 24.4
            elseif compareVersions(unityVersion, self.ConstSemVer['2019_3_7']) >= 0 then
                version = 24.3
            end
            return version
        end,
        [2020] = function(self, unityVersion)
            local version = 24.3
            if compareVersions(unityVersion, self.ConstSemVer['2020_2_4']) >= 0 then
                version = 27.1
            elseif compareVersions(unityVersion, self.ConstSemVer['2020_2']) >= 0 then
                version = 27
            elseif compareVersions(unityVersion, self.ConstSemVer['2020_1_11']) >= 0 then
                version = 24.4
            end
            return version
        end,
        [2021] = function(self, unityVersion)
            return compareVersions(unityVersion, self.ConstSemVer['2021_2']) >= 0 and 29 or 27.2
        end,
        [2022] = function(self, unityVersion)
            local version = 29
            if compareVersions(unityVersion, self.ConstSemVer['2022_3_41']) >= 0 then
                version = 31
            elseif compareVersions(unityVersion, self.ConstSemVer['2022_2']) >= 0 then
                version = 29.1
            end
            return version
        end,
        [2023] = function(self, unityVersion) return 31 end,
    },
    
    ReadUnityVersion = function()
        local version = {2018, 2019, 2020, 2021, 2022, 2023, 2024}
        local lm = gg.getRangesList('libmain.so')
        if #lm > 0 then
            local f = io.open(lm[1].name, "rb")
            if f then
                local libMain = f:read("*a")
                f:close()
                for i, v in pairs(version) do
                    if libMain:find(v) then
                        local g = libMain:gmatch(v .. "(.-)_")
                        if g then
                            local sub = g()
                            if sub then
                                local versionName = v .. sub
                                local major, minor, patch = string.gmatch(versionName, "(%d+)%p(%d+)%p(%d+)")()
                                if major then
                                    return { major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch), name = versionName}
                                end
                            end
                        end
                    end
                end
            end
        end
        return { major = 2022, minor = 3, patch = 0 }
    end,
    
    ChooseVersion = function(self, version, globalMetadataHeader)
        if not version then
            local unityVersion = self.ReadUnityVersion()
            if not unityVersion then
                version = 31
            else
                version = self.Year[unityVersion.major] or 31
                if type(version) == 'function' then
                    version = version(self, unityVersion)
                end
            end
        end
        if version > 31 then
            version = 31
        end
        return version
    end,
}

return setmetatable(VersionEngine, {
    __call = function(self, ...)
        return self:ChooseVersion(...)
    end
})
end)
__bundle_register("config", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
   name = "Il2CppGG",
   version = '1.0.5',
   author = "LeThi9GG",
   build = {
      input = "init",
      output = "build/Il2CppGG.lua",
   }
}
end)
__bundle_register("utils.Patch", function(require, _LOADED, __bundle_register, __bundle_modules)
local x64 = Il2Cpp.x64

local asmLT9 = {
    type = {
        [2] = 4, [4] = 4, [5] = 4, [6] = 4, [7] = 4, [8] = 4, [9] = 4, [12] = 16, [13] = 64,
    },
    op_int = x64 and "~A8 MOV W0, #" or "~A MOVT R0, #",
    op_return = (x64 and "~A8 RET" or "~A BX	 LR"),
    
    gV = function(self, value, flags)
        if flags == gg.TYPE_DWORD then
            local high16 = bit32.rshift(value, 16)
            high16 = bit32.band(high16, 0xFFFF)
            high16 = high16 + 1
            return bit32.band(bit32.lshift(high16, 16), 0xFFFFFFFF)
        elseif flags == gg.TYPE_FLOAT then
            local int_val = self:floatToInt(value)
            local high16 = bit32.rshift(int_val, 16)
            high16 = bit32.band(high16, 0xFFFF)
            high16 = high16 + 1
            int_val = bit32.band(bit32.lshift(high16, 16), 0xFFFFFFFF)
            if x64 then return int_val else return high16 end
        else
            error("Unsupported flags type in gV")
        end
    end,
    
    floatToInt = function(self, f)
        local sign = 0
        if f < 0 then
            sign = 0x80000000
            f = -f
        end
        local mantissa, exponent = math.frexp(f)
        if f == 0 then
            return 0
        elseif f == math.huge then
            return bit32.bor(sign, 0x7F800000)
        end
        mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
        exponent = exponent + 126
        if exponent <= 0 then
            mantissa = math.ldexp(mantissa, exponent - 1)
            exponent = 0
        elseif exponent >= 0xFF then
            return bit32.bor(sign, 0x7F800000)
        end
        mantissa = math.floor(mantissa + 0.5)
        return bit32.bor(sign, bit32.lshift(bit32.band(exponent, 0xFF), 23), bit32.band(mantissa, 0x7FFFFF))
    end,
    
    getInt = function(self, value, param)
        local param = (param and self.op_int:gsub(0, param) or self.op_int)
        if value > 0 and value < 65535 and not x64 then
            return param:gsub("T", "W") .. value
        elseif x64 and value > -65535 and value < 65535 then
            return param .. value
        end
        local value = self:gV(value, gg.TYPE_DWORD)
        return param .. (x64 and value or math.floor(value / 65535))
    end,
    
    getFloat = function(self, value, param)
        local param = (param and self.op_int:gsub(0, param) or self.op_int)
        if x64 then
            return param .. self:gV(value, gg.TYPE_FLOAT)
        else
            local high16 = self:gV(value, gg.TYPE_FLOAT)
            return param .. high16
        end
    end,
    
    setValues = function(self, address, value, types, flags)
        local results, result = self:init(address, value, types, flags)
        result = gg.getValues(result)
        gg.setValues(results)
        return function() gg.setValues(result) end
    end,
    
    init = function(self, address, value, types, flags)
        local value = value or 0
        local fix
        for i = 0, 4 do
            local val = Il2Cpp.gV(address + (i * 4), gg.TYPE_DWORD)
            if val and gg.disasm(Il2Cpp.armType, 0, val):find(x64 and "RET" or "BX	 LR") then
                fix = true
                break
            end
        end
        local Flags = {[gg.TYPE_DWORD] = "X",[gg.TYPE_FLOAT] = "S",[gg.TYPE_DOUBLE] = "D"}
        local flags = flags or (self.type[types] or gg.TYPE_DWORD)
        local results
        if x64 and (value == 0 or not value) then
            results = {{address = address, flags = gg.TYPE_DWORD, value = "~A8 MOV W0, WZR"}, {address = address + 4, flags = gg.TYPE_DWORD, value = self.op_return}}
        else
            results = fix and {{address = address, flags = gg.TYPE_DWORD, value = flags == gg.TYPE_DWORD and self:getInt(value) or self:getFloat(value)}, {address = address + 4, flags = gg.TYPE_DWORD, value = self.op_return}} 
            or {{address = address, flags = gg.TYPE_DWORD, value = (x64 and "~A8 LDR	 "..(Flags[flags]).."0, [PC,#0x8]" or "~A LDR	 R0, [PC]")},
                {address = address + 4, flags = gg.TYPE_DWORD, value = (x64 and "~A8 RET" or "~A BX	 LR")},
                {address = address + 8, flags = flags, value = value}}
        end
        local result = {}
        for i = 0, 4 do
            result[i+1] = {address = address + (i * 4), flags = gg.TYPE_DWORD}
        end
        return results, gg.getValues(result)
    end
}

return setmetatable({}, {
    __index = asmLT9,
    __call = asmLT9.init 
})
end)
__bundle_register("core.Meta", function(require, _LOADED, __bundle_register, __bundle_modules)
local Meta = {
    dataPath = Il2Cpp.Info.path .. "-Il2CppGG.lua",
    ranges = {
        A = gg.REGION_ANONYMOUS,
        Ca = gg.REGION_C_ALLOC,
        O = gg.REGION_OTHER
    }
}

local function isImage(addr)
    if not addr or addr == 0 then return false end
    local imageStr = Il2Cpp.Utf8ToString(Il2Cpp.GetPtr(addr))
    local check = string.find(imageStr, ".-%.dll") or string.find(imageStr, "__Generated")
    return check and imageStr
end

function Meta:init(globalMetadataHeader, Version)
    local globalMetadataHeader = globalMetadataHeader or Il2Cpp.Meta.metaStart
    local sanity = Il2Cpp.gV(globalMetadataHeader, 4)
    if sanity ~= -89056337 then
        Il2Cpp.log:warn("Metadata file supplied is not valid metadata file.")
    end

    local version = Il2Cpp.gV(globalMetadataHeader + 4, 4)
    if version < 16 or version > 31 then
        self.Obf = true
        self.Version = Version
    else
        self.Version = version
    end
    
    self.Header = Il2Cpp.Il2CppGlobalMetadataHeader(globalMetadataHeader)
    
    if not self.Obf then
        for k, v in pairs(self.Header) do
            local _, __ = k:find("Offset")
            if __ == #k and type(v) == "number" then
                self.Header[k] = globalMetadataHeader + v
            end
        end
    end
    
    Il2Cpp.typeCount = Il2Cpp.pMetadataRegistration.typesCount
    Il2Cpp.typeSize = Il2Cpp.Il2CppTypeDefinition:GetSize()
    Il2Cpp.stringDef = self.Header.stringOffset
    
    local i = 1
    while i < 100 do 
        local addrs = Il2Cpp.GetPtr(Il2Cpp.metaPtr + (i * Il2Cpp.pointSize))
        if addrs and addrs > 1000 then
            local klass = Il2Cpp.GetPtr(addrs)
            if isImage(Il2Cpp.GetPtr(klass)) then
                Il2Cpp.typeDef = addrs
                break
            end
        end
        i = i + 1
    end
    
    if not Il2Cpp.imageDef and Il2Cpp.metaPtr then
        Il2Cpp.imageDef = Il2Cpp.GetPtr(Il2Cpp.metaPtr)
    end
    
    self.imageDefs = Il2Cpp.Image()
    return self
end

Meta.behaviorForTypes = {
    [2] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_BYTE) end,
    [3] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_BYTE) end,
    [4] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_BYTE) end,
    [5] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_BYTE) end,
    [6] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_WORD) end,
    [7] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_WORD) end,
    [8] = function(blob)
        local self = Il2Cpp.Meta
        return Il2Cpp.Version < 29 and self.ReadNumberConst(blob, gg.TYPE_DWORD) or self.ReadCompressedInt32(blob)
    end,
    [9] = function(blob)
        local self = Il2Cpp.Meta
        return Il2Cpp.Version < 29 and Il2Cpp.FixValue(self.ReadNumberConst(blob, gg.TYPE_DWORD)) or self.ReadCompressedUInt32(blob)
    end,
    [10] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_QWORD) end,
    [11] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_QWORD) end,
    [12] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_FLOAT) end,
    [13] = function(blob) return Il2Cpp.Meta.ReadNumberConst(blob, gg.TYPE_DOUBLE) end,
    [14] = function(blob)
        local self = Il2Cpp.Meta
        local length, offset = 0, 0
        if Il2Cpp.Version >= 29 then
            length, offset = self.ReadCompressedInt32(blob)
        else
            length = self.ReadNumberConst(blob, gg.TYPE_DWORD) 
            offset = 4
        end
        if length ~= -1 then
            return Il2Cpp.Utf8ToString(blob + offset, length)
        end
        return ""
    end
}

Meta.ReadCompressedUInt32 = function(Address)
    local val, offset = 0, 0
    local read = gg.getValues({
        { address = Address, flags = gg.TYPE_BYTE },
        { address = Address + 1, flags = gg.TYPE_BYTE },
        { address = Address + 2, flags = gg.TYPE_BYTE },
        { address = Address + 3, flags = gg.TYPE_BYTE }
    })
    local read1 = read[1].value & 0xFF
    offset = 1
    if (read1 & 0x80) == 0 then
        val = read1
    elseif (read1 & 0xC0) == 0x80 then
        val = (read1 & ~0x80) << 8
        val = val | (read[2].value & 0xFF)
        offset = offset + 1
    elseif (read1 & 0xE0) == 0xC0 then
        val = (read1 & ~0xC0) << 24
        val = val | ((read[2].value & 0xFF) << 16)
        val = val | ((read[3].value & 0xFF) << 8)
        val = val | (read[4].value & 0xFF)
        offset = offset + 3
    elseif read1 == 0xF0 then
        val = gg.getValues({{address = Address + 1, flags = gg.TYPE_DWORD}})[1].value
        offset = offset + 4
    elseif read1 == 0xFE then
        val = 0xffffffff - 1
    elseif read1 == 0xFF then
        val = 0xffffffff
    end
    return val, offset
end

Meta.ReadCompressedInt32 = function(Address)
    local encoded, offset = Il2Cpp.Meta.ReadCompressedUInt32(Address)
    if encoded == 0xffffffff then
        return -2147483647 - 1
    end
    local isNegative = (encoded & 1) == 1
    encoded = encoded >> 1
    if isNegative then
        return -(encoded + 1)
    end
    return encoded, offset
end

Meta.ReadNumberConst = function(Address, ggType)
    return gg.getValues({{ address = Address, flags = ggType }})[1].value
end

Meta.StringCacheApi = {}
function Meta:FindStringApi(Name)
	if self.StringCacheApi[Name] then
	    return self.StringCacheApi[Name]
	end
	local result, chars = {}, {};
	for key, name in pairs({string.lower(Name), string.upper(Name), string.upper(Name:sub(1, 1)) .. Name:sub(2, #Name), Name}) do
		local SearchName = ":" .. name;
		gg.setRanges(-1);
		gg.clearResults();
		gg.searchNumber(SearchName, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, Il2Cpp.stringDef, self.metaEnd);
    	gg.refineNumber(SearchName:sub(1, 2), gg.TYPE_BYTE);
		local t = gg.getResults(gg.getResultsCount());
		gg.clearResults();
		for k, v in pairs(t) do
    		local char = {address=(v.address + 1),flags=1};
			while true do
			    local vals = gg.getValues({char})
                if not vals or not vals[1] then break end
				local _char = string.char(vals[1].value & 255);
				char.address = char.address - 1;
				if string.find(_char, "[%z%s]") then break end
			end
			local address = char.address + 2;
			local nameStr = Il2Cpp.Utf8ToString(address);
			chars[#chars + 1] = nameStr;
			result[#result + 1] = {address=address,flags=1,name=nameStr};
		end
	end
	self.StringCacheApi[Name] = {chars,result};
	return { chars = chars, results = result }
end

Meta.PointerStringApiCache = {}
function Meta:GetPointersToStringApi(name)
    local Result = self:FindStringApi(name)
    local Results = Result.results
    if self.PointerStringApiCache[tostring(Results)] then
	    return self.PointerStringApiCache[tostring(Results)]
	end
	local pointerString = {}
	local ResultsPointer = {}
    gg.clearResults()
    gg.setRanges(self.regionClass)
    gg.loadResults(Results)
    gg.searchPointer(0);
    ResultsPointer = gg.getResults(gg.getResultsCount())
    gg.clearResults()
    self.PointerStringApiCache[tostring(Results)] = ResultsPointer
    return ResultsPointer, Result
end

function Meta.GetPointersToString(name, ranges)
    local ranges = ranges or Il2Cpp.Meta
    gg.clearResults()
    gg.setRanges(-1)
    gg.searchNumber(string.format("Q 00 '%s' 00", name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL,
        ranges.metaStart, ranges.metaEnd)
    if gg.getResultsCount() == 0 then
        gg.searchNumber(string.format("Q 00 '%s' ", name), gg.TYPE_BYTE, false, gg.SIGN_EQUAL,
        ranges.metaStart, ranges.metaEnd)
    end
    local results = gg.getResults(1, 1)
    if #results == 0 then
        error(string.format("Không tìm thấy lớp %s trong global-metadata", name))
    end
    gg.setRanges(Il2Cpp.Meta.regionClass)
    local res = Il2Cpp.searchPtr(results[1].address, Il2Cpp.MainType)
    gg.clearResults()
    if #res == 0 then
        error(string.format("Không tìm thấy con trỏ cho lớp %s %d", name, results[1].address))
    end
    return res
end

function Meta:GetStringFromIndex(index)
    return Il2Cpp.Utf8ToString(Il2Cpp.stringDef + index)
end

function Meta:GetGenericContainer(index)
    if self.Header.genericContainersOffset > index then
        index = self.Header.genericContainersOffset + (index * Il2Cpp.Il2CppGenericContainer.size)
    end
    return Il2Cpp.Il2CppGenericContainer(index)
end

function Meta:GetGenericParameter(index)
    if self.Header.genericParametersOffset > index then
        index = self.Header.genericParametersOffset + (index * Il2Cpp.Il2CppGenericParameter.size)
    end
    return Il2Cpp.Il2CppGenericParameter(index)
end

function Meta:GetGenericContainerParams(genericContainer)
    local genericParameterNames = {}
    for i = 1, genericContainer.type_argc do
        local genericParameterIndex = genericContainer.genericParameterStart + i
        local genericParameter = self:GetGenericParameter(genericParameterIndex)
        genericParameterNames[i] = self:GetStringFromIndex(genericParameter.nameIndex)
    end
    return "<" .. table.concat(genericParameterNames, ", ") .. ">"
end

function Meta:GetGenericInsts(index)
    local index = Il2Cpp.pMetadataRegistration.genericInsts + (index * Il2Cpp.type.Pointer.size)
    return Il2Cpp.Il2CppGenericInst(index)
end

function Meta:GetTypeDefinition(typeDef)
    return Il2Cpp.Il2CppTypeDefinition(typeDef.typeDefinition or typeDef.typeMetadataHandle)
end

function Meta:GetMethodDefinition(index)
    local index = self.Header.methodsOffset + (index * Il2Cpp.Il2CppMethodDefinition.size)
    return Il2Cpp.Il2CppMethodDefinition(index)
end

function Meta:GetParameterDefinition(index)
    local index = self.Header.parametersOffset + (index * Il2Cpp.Il2CppParameterDefinition.size)
    return Il2Cpp.Il2CppParameterDefinition(index)
end

return setmetatable({}, {
    __index = Meta,
    __call = Meta.init 
})
end)
__bundle_register("core.Universalsearcher", function(require, _LOADED, __bundle_register, __bundle_modules)
local Searcher = {
    searchWord = ":EnsureCapacity",
    tokenParam = 134217729,
    
    ranges = {
        A = gg.REGION_ANONYMOUS,
        Ca = gg.REGION_C_ALLOC,
        O = gg.REGION_OTHER
    },
    
    FindGlobalMetaData = function(self)
        gg.clearResults()
        gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_ANONYMOUS | gg.REGION_OTHER)
        local globalMetadata = gg.getRangesList('global-metadata.dat')
        if not self:IsValidData(globalMetadata) then
            globalMetadata = gg.getRangesList("dev/zero")
        end
        if not self:IsValidData(globalMetadata) then
            globalMetadata = {}
            local EnsureCapacity = {}
            for k, v in ipairs({ gg.REGION_C_ALLOC, gg.REGION_ANONYMOUS, gg.REGION_OTHER }) do
                gg.clearResults()
                gg.setRanges(v)
                gg.searchNumber(self.searchWord, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, nil, nil, 1)
                if gg.getResultsCount() > 0 then
                    gg.refineNumber(self.searchWord:sub(1, 2), gg.TYPE_BYTE)
                    EnsureCapacity = gg.getResults(gg.getResultsCount())
                    gg.clearResults()
                    break
                end 
            end
            for k, v in ipairs(gg.getRangesList()) do
                if (v.state == 'Ca' or v.state == 'A' or v.state == 'Cd' or v.state == 'Cb' or v.state == 'Ch' or v.state == 'O') then
                    for key, val in ipairs(EnsureCapacity) do
                        globalMetadata[#globalMetadata + 1] = (Il2Cpp.FixValue(v.start) <= Il2Cpp.FixValue(val.address) and Il2Cpp.FixValue(val.address) < Il2Cpp.FixValue(v['end'])) and v or nil
                    end
                end
            end
        end
        local value = -89056337
        if #globalMetadata > 0 and gg.getValues({{address = globalMetadata[1].start, flags = 4}})[1].value ~= value then
            gg.searchNumber(value, 4, false, gg.SIGN_EQUAL, globalMetadata[1].start, globalMetadata[#globalMetadata]['end'])
            if gg.getResultsCount() > 0 then
                globalMetadata[1].start = gg.getResults(1)[1].address
            end
        end
        return type(globalMetadata) == "table" and globalMetadata[1] and globalMetadata[1].start or 0, globalMetadata[#globalMetadata] and globalMetadata[#globalMetadata]['end'] or 0, 0
    end,

    IsValidData = function(self, globalMetadata)
        if #globalMetadata ~= 0 then
            gg.searchNumber(self.searchWord, gg.TYPE_BYTE, false, gg.SIGN_EQUAL, globalMetadata[1].start, globalMetadata[#globalMetadata]['end'], 1)
            if gg.getResultsCount() > 0 then
                gg.clearResults()
                return true
            end
        end
        return false
    end,

    FindIl2cpp = function(Il2CppMetadataRegistration)
        if Il2CppMetadataRegistration then
            local rangesList = gg.getRangesList()
            for k, v in ipairs(rangesList) do
                if v.start > Il2CppMetadataRegistration and Il2CppMetadataRegistration < v['end'] then
                    local i = k
                    while i > 0 do 
                        local vals = gg.getValues({{address = rangesList[i].start, flags = 4}})
                        if vals and vals[1] and vals[1].value == 0x464C457F then
                            return rangesList[i].start, v['end']
                        end 
                        i = i - 1 
                    end 
                end
            end 
            Il2Cpp.log:error("FindIl2cpp not found Il2CppMetadataRegistration: " .. tostring(Il2CppMetadataRegistration))
        end
                    
        local il2cpp = gg.getRangesList('libil2cpp.so')
        if #il2cpp == 0 then
            il2cpp = gg.getRangesList('split_config.')
            local _il2cpp = {}
            gg.setRanges(gg.REGION_CODE_APP)
            for k, v in ipairs(il2cpp) do
                if (v.state == 'Xa') then
                    gg.searchNumber(':il2cpp', gg.TYPE_BYTE, false, gg.SIGN_EQUAL, v.start, v['end'])
                    if (gg.getResultsCount() > 0) then
                        _il2cpp[#_il2cpp + 1] = v
                        gg.clearResults()
                    end
                end
            end
            il2cpp = _il2cpp
        else
            local _il2cpp = {}
            for k,v in ipairs(il2cpp) do
                local vals = gg.getValues({{address = v.start, flags = 4}})
                local Value = vals and vals[1] and vals[1].value or 0
                if Value==0x464C457F or Value==263434879 then
                    _il2cpp[#_il2cpp + 1] = v
                end
            end
            if #_il2cpp > 0 then
                il2cpp[1] = _il2cpp[#_il2cpp]
            end
        end
		
        return il2cpp[1] and il2cpp[1].start or 0, il2cpp[#il2cpp] and il2cpp[#il2cpp]['end'] or 0
    end,
    
    Il2CppSearchPointer = function(config)
        local ranges = config.ranges or {gg.REGION_C_BSS, gg.REGION_ANONYMOUS, gg.REGION_OTHER}
        for i, range in ipairs(ranges) do 
            gg.clearResults();
    	    gg.setRanges(range);
    	    gg.searchNumber(config.address, Il2Cpp.MainType, nil, nil, config.startAddrs, config.endAddrs, config.endResults);
    	    
    	    if gg.getResultsCount() == 0 and AndroidInfo.platform and AndroidInfo.sdk >= 30 then
                gg.searchNumber(tostring(config.address | 0xB400000000000000), Il2Cpp.MainType, nil, nil, config.startAddrs, config.endAddrs, config.endResults);
            end
            
            local t = gg.getResults(gg.getResultsCount())
            gg.clearResults();
            if #t > 0 then
                return t
            end
        end
    end,

    Il2CppMetadataRegistration = function(self, globalMetadataHeader)
        Il2Cpp.classPointer = Il2Cpp.Version < 27 and (AndroidInfo.platform and 24 or 12) or (AndroidInfo.platform and 40 or 20);
        local gmt = gg.getRangesList("global-metadata.dat");
	    local addrs = ((gmt and #gmt > 0) and gmt[1].start) or globalMetadataHeader
	    
        local startAddrs = Il2Cpp.il2cppStart
	    local config = {
	        address = addrs,
	        ranges = {gg.REGION_C_BSS, gg.REGION_ANONYMOUS, gg.REGION_OTHER},
	        endResults = 1,
	        startAddrs = startAddrs
	    }
	    local t = self.Il2CppSearchPointer(config)
	    if not t then
	        config.startAddrs = nil
	        t = self.Il2CppSearchPointer(config)
	        if not t then
	            Il2Cpp.log:error("Il2CppSearchPointer failed for address: " .. tostring(config.address))
	        end
	    end
	    
	    Il2Cpp.metaPtr = t[1].address
		Il2Cpp.log:info("Il2Cpp.metaPtr: " .. Il2Cpp.ToHex(Il2Cpp.metaPtr))
	    
	    local i = 1
	    while i < 100 do 
	        local addr = Il2Cpp.metaPtr - (i * Il2Cpp.pointSize)
            local targetAddr = Il2Cpp.GetPtr(addr)
            if targetAddr > 0 then
                local pMetaReg = Il2Cpp.Il2CppMetadataRegistration(targetAddr)
                local rangeVals = gg.getValuesRange({{address = targetAddr}})
                local Range = rangeVals and rangeVals[1] or ""
                if (Range == "Cd" or Range == "O" or Range == "A") and pMetaReg.typeDefinitionsSizesCount == pMetaReg.fieldOffsetsCount then
                    Il2Cpp.metaReg = targetAddr
                    Il2Cpp.il2cppReg = Il2Cpp.GetPtr(addr + Il2Cpp.pointSize)
                    break
                end 
            end
            i = i + 1
        end
		Il2Cpp.log:info("Il2Cpp.metaReg: " .. Il2Cpp.ToHex(Il2Cpp.metaReg or 0))
		Il2Cpp.log:info("Il2Cpp.il2cppReg: " .. Il2Cpp.ToHex(Il2Cpp.il2cppReg or 0))
        
        Il2Cpp.pMetadataRegistration = Il2Cpp.Il2CppMetadataRegistration(Il2Cpp.metaReg)
        Il2Cpp.pCodeRegistration = Il2Cpp.Il2CppCodeRegistration(Il2Cpp.il2cppReg)
    end
}

return Searcher
end)
__bundle_register("api.Class", function(require, _LOADED, __bundle_register, __bundle_modules)
local Dump = require "utils.Dump"
local Class = {
    IsClassCache = {},
    NameOffset = (Il2Cpp.x64 and 0x10 or 0x8),
}

function Class.GetName(klass)
    local Name = klass.name or ""
    local index = Name:find("`")
    if index then
        Name = Name:sub(1, index - 1)
        local indexContainer = klass.genericContainerIndex or klass.genericContainerHandle
        if indexContainer then
            local genericContainer = Il2Cpp.Meta:GetGenericContainer(indexContainer)
            local genericParameterStart = genericContainer.genericParameterStart
            local type_argc = {}
            for i = 1, genericContainer.type_argc do
                local genericParameter = Il2Cpp.Meta:GetGenericParameter(genericParameterStart + i)
                type_argc[#type_argc+1] = Il2Cpp.Meta:GetStringFromIndex(genericParameter.nameIndex)
            end
            Name = Name .. "<" .. table.concat(type_argc, ", ") .. ">"
        end
    end
    return Name
end

function Class.GetNamespace(klass)
    return klass.namespaze or ""
end

function Class.GetImage(klass)
    return Il2Cpp.Utf8ToString(Il2Cpp.GetPtr(klass.image))
end

function Class.GetParent(klass)
    return Class(klass.parent)
end

function Class.IsValueType(klass)
    return klass:GetParent():GetName() == "ValueType"
end

function Class.IsEnum(klass)
    return klass:GetParent():GetName() == "Enum"
end

function Class.GetFields(klass)
    if type(klass.fields) == "table" then return klass.fields end
    local fields = {}
    local iter = 0
    while iter < klass.field_count do
        fields[#fields + 1] = Il2Cpp.Field(klass.fields + iter * Il2Cpp.FieldInfo.size)
        iter = iter + 1
    end
    klass.fields = fields
    return fields
end

function Class.GetField(klass, name)
    for _, field in ipairs(klass:GetFields()) do
        if field:GetName() == name then
            return field, _ - 1
        end
    end
    return nil
end

function Class.GetMethods(klass)
    if type(klass.methods) == "table" then return klass.methods end
    local methods = {}
    local iter = 0
    while iter < klass.method_count do
        methods[#methods + 1] = Il2Cpp.Method(Il2Cpp.GetPtr(klass.methods + iter * Il2Cpp.pointSize))
        iter = iter + 1
    end
    klass.methods = methods
    return methods
end

function Class.GetMethod(klass, name, paramCount)
    for _, method in ipairs(klass:GetMethods()) do
        if method:GetName() == name and (not paramCount or method.parameters_count == paramCount) then
            return method
        end
    end
    return nil
end

function Class.GetInterfaces(klass)
    if type(klass.implementedInterfaces) == "table" then return klass.implementedInterfaces end
    local interfaces = {}
    local iter = 0
    while iter < klass.interfaces_count do
        interfaces[#interfaces + 1] = Class(Il2Cpp.GetPtr(klass.implementedInterfaces + iter * Il2Cpp.pointSize))
        iter = iter + 1
    end
    klass.implementedInterfaces = interfaces
    return interfaces
end

function Class.GetIndex(klass)
    local index = klass.byval_arg and klass.byval_arg.data or 0
    if Il2Cpp.Meta.Header.typeDefinitionsOffset <= index and (Il2Cpp.Meta.Header.typeDefinitionsOffset + Il2Cpp.Meta.Header.typeDefinitionsSize) >= index then
        return (index - Il2Cpp.Meta.Header.typeDefinitionsOffset) / Il2Cpp.typeSize
    elseif index <= Il2Cpp.typeCount then
        return index
    end
end

function Class.GetPointersToIndex(index)
    if Il2Cpp.Meta.Header.typeDefinitionsOffset <= index and (Il2Cpp.Meta.Header.typeDefinitionsOffset + Il2Cpp.Meta.Header.typeDefinitionsSize) >= index then
        index = (index - Il2Cpp.Meta.Header.typeDefinitionsOffset) / Il2Cpp.typeSize
    elseif index > Il2Cpp.typeCount then
        return index
    end
    return Il2Cpp.GetPtr(Il2Cpp.typeDef + (index * Il2Cpp.pointSize))
end

function Class.IsClassInfo(Address)
    if not Address or Address == 0 then return nil end
    if Class.IsClassCache[Address] then
        return Class.IsClassCache[Address]
    end
    local vals = gg.getValues({{address = Il2Cpp.FixValue(Address), flags = Il2Cpp.pointer}})
    if not vals or not vals[1] then return nil end
    local imageAddress = Il2Cpp.FixValue(vals[1].value)
    local vals2 = gg.getValues({{address = imageAddress, flags = Il2Cpp.pointer}})
    if not vals2 or not vals2[1] then return nil end
    local imageStr = Il2Cpp.Utf8ToString(Il2Cpp.FixValue(vals2[1].value))
    local check = string.find(imageStr, ".-%.dll") or string.find(imageStr, "__Generated")
    Class.IsClassCache[Address] = check and imageStr or nil
    return Class.IsClassCache[Address]
end

function Class:GetTypeDef()
    return self.typeDefinition or self.typeMetadataHandle
end 

function Class:From(searchParams, addList)
    if Il2Cpp.__cache.Class[searchParams] then return Il2Cpp.__cache.Class[searchParams] end
    local klass = {}
    if type(searchParams) == "string" or type(searchParams) == "table" then
        local res = type(searchParams) == "table" and searchParams or Il2Cpp.Meta.GetPointersToString(searchParams)
        for i, v in ipairs(res) do
            local addr = v.address - Class.NameOffset
            local imageName = Class.IsClassInfo(addr)
            if imageName then
                local kls = Il2Cpp.Il2CppClass(addr, addList)
                kls.address = addr
                kls.class_index = Class.GetIndex(kls)
                klass[#klass+1] = setmetatable(kls, {
                    __index = Class,
                    __name = (kls.namespaze ~= "" and kls.namespaze .. "." or "") .. kls.name
                })
            end
        end
    else
        local addr = Class.GetPointersToIndex(searchParams)
        local kls = Il2Cpp.Il2CppClass(addr, addList)
        kls.address = addr
        kls.class_index = Class.GetIndex(kls)
        klass = setmetatable(kls, {
            __index = Class,
            __name = (kls.namespaze ~= "" and kls.namespaze .. "." or "") .. kls.name
        })
    end
    Il2Cpp.__cache.Class[searchParams] = klass
    return klass
end

function Class.Dump(klass, config)
    return Dump(klass, config)
end

return setmetatable(Class, {
    __call = Class.From
})
end)
__bundle_register("utils.Dump", function(require, _LOADED, __bundle_register, __bundle_modules)
function Dump(typeDef, config)
    local Il2CppConstants = Il2Cpp.Il2CppConstants
    local config = config or {
        DumpAttribute = false,
        DumpField = true,
        DumpProperty = true,
        DumpMethod = true,
        DumpFieldOffset = true,
        DumpMethodOffset = true,
        DumpTypeDefIndex = false,
    }
    local output = {}
    local extends = {}
    
    local typeDefs = Il2Cpp.Il2CppTypeDefinition(typeDef.typeMetadataHandle or typeDef.typeDefinition)
    
    if typeDef.parent and typeDef.parent >= 0 then
        local parent = typeDef:GetParent()
        local parentName = parent:GetName()
        if not typeDef:IsValueType() and not typeDef:IsEnum() and parentName ~= "object" then
            table.insert(extends, parentName)
        end
    end
    
    table.insert(output, string.format("\n// Namespace: %s", typeDef:GetNamespace()))
    
    local visibility = bit32.band(typeDefs.flags, Il2CppConstants.TYPE_ATTRIBUTE_VISIBILITY_MASK)
    local visibilityStr = ""
    if visibility == Il2CppConstants.TYPE_ATTRIBUTE_PUBLIC or visibility == Il2CppConstants.TYPE_ATTRIBUTE_NESTED_PUBLIC then
        visibilityStr = "public "
    elseif visibility == Il2CppConstants.TYPE_ATTRIBUTE_NOT_PUBLIC then
        visibilityStr = "internal "
    end
    
    local typeKind = typeDef:IsEnum() and "enum " or (typeDef:IsValueType() and "struct " or "class ")
    local typeName = typeDef:GetName()
    local extendsStr = #extends > 0 and string.format(" : %s", table.concat(extends, ", ")) or ""
    table.insert(output, string.format("%s%s%s%s\n{", visibilityStr, typeKind, typeName, extendsStr))
    
    if config.DumpField and typeDef.field_count > 0 then
        table.insert(output, "\t// Fields")
        for i = 0, typeDef.field_count - 1 do
            local fieldDef = type(typeDef.fields) == "number" and Il2Cpp.Field(typeDef.fields + i * Il2Cpp.FieldInfo.size) or typeDef.fields[i+1]
            if fieldDef and fieldDef.ToString then
                table.insert(output, fieldDef:ToString(i))
            end
        end
    end

    if config.DumpMethod and typeDef.method_count > 0 then
        table.insert(output, "\n\t// Methods")
        for i = 0, typeDef.method_count - 1 do
            local methodDef = type(typeDef.methods) == "number" and Il2Cpp.Method(Il2Cpp.GetPtr(typeDef.methods + i * Il2Cpp.pointSize)) or typeDef.methods[i+1]
            if methodDef and methodDef.ToString then
                table.insert(output, "")
                table.insert(output, methodDef:ToString())
            end
        end
    end
    table.insert(output, "}")
    return table.concat(output, "\n")
end

return Dump
end)
__bundle_register("api.Field", function(require, _LOADED, __bundle_register, __bundle_modules)
local Field = {
    DumpFieldValues = true
}

function Field.GetName(field)
    return field.name or ""
end

function Field.GetParent(field)
    if type(field.parent) == "table" then
        return field.parent
    end
    field.parent = Il2Cpp.Class(field.parent)
    return field.parent
end

function Field.GetOffset(field)
    return field.offset or 0
end

function Field.GetType(field)
    if type(field.type) == "table" then
        return field.type
    end
    field.type = Il2Cpp.Type(field.type)
    return field.type
end

function Field.IsInstance(field)
    local attrs = Field.GetType(field).attrs or 0
    return bit32.band(attrs, 0x0010) == 0
end

function Field.ToString(field, fieldIndex)
    local output = {}
    local fieldDef = field
    local fieldType = fieldDef:GetType()
    local fieldName = fieldDef:GetName()
    local fieldTypeName = tostring(fieldType)
    table.insert(output, string.format("\tpublic %s %s; // 0x%x", fieldTypeName, fieldName, fieldDef:GetOffset()))
    return table.concat(output, "\n")
end

function Field:From(searchParams)
    if Il2Cpp.__cache.Field[searchParams] then return Il2Cpp.__cache.Field[searchParams] end
    local field = {}
    if type(searchParams) == "string" or type(searchParams) == "table" then
        local res = type(searchParams) == "table" and searchParams or Il2Cpp.Meta.GetPointersToString(searchParams)
        for i, v in ipairs(res) do
            local addr = Il2Cpp.GetPtr(v.address + (Il2Cpp.pointSize * 2))
            local imageName = Il2Cpp.Class.IsClassInfo(addr)
            if imageName then
                local kls = Il2Cpp.FieldInfo(v.address)
                kls.address = v.address
                field[#field+1] = setmetatable(kls, {
                    __index = Field,
                    __name = kls.name
                })
            end
        end
    elseif type(searchParams) == "number" then
        field = Il2Cpp.FieldInfo(searchParams)
        field.address = searchParams
        return setmetatable(field, {
            __index = Field,
            __name = field.name
        })
    end
    Il2Cpp.__cache.Field[searchParams] = field
    return field
end

return setmetatable(Field, {
    __call = Field.From
})
end)
__bundle_register("api.Method", function(require, _LOADED, __bundle_register, __bundle_modules)
local Method = require "utils.Hook"
Method.DumpParamValues = true

function Method.GetName(method)
    return method.name or ""
end

function Method.SetValue(method, value)
    local func = Il2Cpp.Patch:setValues(method.methodPointer, value, method:GetReturnType().type)
    function method.RestoreValue()
        func()
        method.RestoreValue = nil
    end
end

function Method.GetDeclaringType(method)
    return Il2Cpp.Class(method.klass)
end

function Method.GetReturnType(method)
    return Il2Cpp.Type(method.return_type)
end

function Method.GetParamCount(method)
    return method.parameters_count or 0
end

function Method.ToString(method)
    local output = {}
    local methodDef = method
    local methodPointer = Il2Cpp.FixValue(methodDef.methodPointer)
    if methodPointer > 0 then
        table.insert(output, string.format("\t// RVA: 0x%x Offset: 0x%x VA: 0x%x", methodDef.address, methodPointer - Il2Cpp.il2cppStart, methodPointer))
    else
        table.insert(output, "\t// RVA: -1 Offset: -1")
    end
    table.insert(output, string.format("\tpublic extern %s %s();", tostring(methodDef:GetReturnType()), methodDef:GetName()))
    return table.concat(output, "\n")
end 

function Method:From(searchParams, addList)
    if Il2Cpp.__cache.Method[searchParams] then return Il2Cpp.__cache.Method[searchParams] end
    local method = {}
    if type(searchParams) == "string" or type(searchParams) == "table" then
        local res = type(searchParams) == "table" and searchParams or Il2Cpp.Meta.GetPointersToString(searchParams)
        for i, v in ipairs(res) do
            local addr = Il2Cpp.GetPtr(v.address + (Il2Cpp.pointSize * 2))
            local IsClass = Il2Cpp.Class.IsClassInfo(addr)
            if IsClass then
                v.address = v.address - (Il2Cpp.Version < 29 and Il2Cpp.pointSize * 2 or Il2Cpp.pointSize * 3)
                local kls = Il2Cpp.MethodInfo(v.address, addList)
                kls.address = v.address
                method[#method+1] = setmetatable(kls, {
                    __index = Method,
                    __name = kls.name
                })
            end
        end
    else
        method = Il2Cpp.MethodInfo(searchParams, addList)
        method.address = searchParams
        return setmetatable(method, {
            __index = Method,
            __name = method.name
        })
    end
    Il2Cpp.__cache.Method[searchParams] = method
    return method
end

return setmetatable(Method, {
    __call = Method.From
})
end)
__bundle_register("utils.Hook", function(require, _LOADED, __bundle_register, __bundle_modules)
local gg = gg
local info = gg.getTargetInfo()
local x64 = info.x64

local pointerFlagsType = x64 and 32 or 4
local pointerSize = x64 and 8 or 4
local jumpOpcode = x64 and "h5100005820021FD6" or "h04F01FE5"
local nullOpcode = x64 and "B4000000h" or 0

table.__index = table
setmetatable(table, {
    __call = function(t, ...)
        return setmetatable({}, table):union(...)
    end
})
function table:union(...)
    for i = 1, select('#', ...) do
        local o = select(i, ...)
        if o then
            for k, v in pairs(o) do
                self[k] = v
            end
        end
    end
    return self
end

local hook = {}
hook.flags = {int = "X", float = "S", double = "D", string = "X"}
hook.type = {int = 4, float = 16, double = 64, string = pointerFlagsType}

function hook.addToResults(res, address, flags, value)
    res[#res + 1] = {address = address, flags = flags, value = value}
end

function hook:off()
    if self.on then
        self.on = false
    end
end

setmetatable(hook, {
    __call = function(self, ...)
        return setmetatable({...}, {
            __index = self,
            __call = function(self, ...)
                return self:init(...)
            end
        })
    end
})

hook.call = hook()
hook.method = hook()
hook.field = hook()
hook.param = hook()

return hook
end)
__bundle_register("api.Param", function(require, _LOADED, __bundle_register, __bundle_modules)
local Param = {}

function Param.GetName(param)
    if not param.name then
        param.name = Il2Cpp.Meta:GetStringFromIndex(param.nameIndex or 0)
    end
    return param.name 
end

function Param.GetType(param)
    if not param.type then
        param.type = Il2Cpp.Type(param.typeIndex or 0)
    end
    return param.type
end

function Param:From(param_index, add)
    local param = Il2Cpp.Meta:GetParameterDefinition(param_index, add)
    return setmetatable(param, {
        __index = Param,
        __name = 'Param[' .. param_index .. ']',
        __tostring = function() return tostring(Param.GetType(param)) .. " " .. Param.GetName(param) end
    })
end

return setmetatable(Param, {
    __call = Param.From
})
end)
__bundle_register("api.Object", function(require, _LOADED, __bundle_register, __bundle_modules)
local ObjectApi = {
    regionObject = gg.REGION_ANONYMOUS,

    FilterObjects = function(self, Objects)
        local FilterObjects = {}
        for k, v in ipairs(gg.getValuesRange(Objects)) do
            if v == 'A' then
                FilterObjects[#FilterObjects + 1] = Objects[k]
            end
        end
        return FilterObjects
    end,

    FindObjects = function(self, ClassAddress)
        gg.clearResults()
        gg.setRanges(self.regionObject)
        gg.loadResults({{ address = tonumber(ClassAddress), flags = Il2Cpp.MainType }})
        gg.searchPointer(0)
        local FindsResult = gg.getResults(gg.getResultsCount())
        gg.clearResults()
        local t = {}
        for i, v in ipairs(FindsResult) do
            if Il2Cpp.gV(v.address + Il2Cpp.pointSize) == 0 then
                t[#t+1]=v
            end
        end
        return self:FilterObjects(t)
    end,

    From = function(self, ClassesInfo)
        local Objects = {}
        for j = 1, #ClassesInfo do
            local FindResult = self:FindObjects(ClassesInfo[j].address)
            table.move(FindResult, 1, #FindResult, #Objects + 1, Objects)
        end
        return Objects
    end,
}

return setmetatable(ObjectApi, {
    __call = ObjectApi.From
})
end)
__bundle_register("api.Image", function(require, _LOADED, __bundle_register, __bundle_modules)
local Image = {}

function Image:From(name)
    if not self.__cache then
        if not Il2Cpp.imageSize then
            Il2Cpp.Meta()
        end
        local typeStart = 0
        local addr = Il2Cpp.imageDef or 0
        if addr == 0 then return {} end
        local typeCountOffset = (Il2Cpp.pointSize * 3)
        self.__cache = {}
        for i = 1, (Il2Cpp.imageCount or 1) do
            local imageInfo = gg.getValues({
                {address = addr, flags = Il2Cpp.MainType},
                {address = addr + typeCountOffset, flags = 4},
                {address = addr + (Il2Cpp.pointSize * 2), flags = Il2Cpp.MainType},
                {address = addr + typeCountOffset + (Il2Cpp.pointSize * 5), flags = 4}
            })
            
            local imgName = Il2Cpp.Utf8ToString(Il2Cpp.FixValue(imageInfo[1].value))
            local check = string.find(imgName, ".-%.dll") or string.find(imgName, "__Generated")
            if not check then
                Il2Cpp.imageCount = i 
                break
            end
            self.__cache[i] = setmetatable({
                index = i,
                typeCount = imageInfo[2].value,
                typeStart = typeStart,
                name = imgName,
                assembly = imageInfo[3].value,
                token = imageInfo[4].value
            }, {__index = Image})
            typeStart = typeStart + imageInfo[2].value
            addr = addr + (Il2Cpp.imageSize or 0x38)
        end
    end
    if name then
        for i, v in ipairs(self.__cache) do
            if v.name == name or v.name == (name .. ".dll") then
                return v
            end
        end
    else
        return self.__cache
    end
end

function Image.GetName(image)
    return image.name or ""
end

function Image.GetTypes(image, exportedOnly)
    local types = {}
    for i = 0, (image.typeCount or 0) - 1 do
        local handle = Il2Cpp.GetPtr(Il2Cpp.typeDef + (image.typeStart + i) * Il2Cpp.pointSize)
        if handle ~= 0 then
            local klass = Il2Cpp.Class(handle)
            if klass and klass.name ~= "<Module>" then
                types[#types + 1] = klass
            end
        end
    end
    return types
end

return setmetatable(Image, {
    __call = Image.From
})
end)
__bundle_register("api.Type", function(require, _LOADED, __bundle_register, __bundle_modules)
local Type = {}

function Type:From(searchParams)
    local searchParams = Il2Cpp.FixValue(searchParams)
    if Type.typeCount and Type.typeCount >= searchParams then 
        searchParams = Il2Cpp.gV(Type.type + (searchParams * Il2Cpp.pointSize), Il2Cpp.pointer)
    end
    if Il2Cpp.__cache.Type[searchParams] then return Il2Cpp.__cache.Type[searchParams] end
    local typeStruct = Il2Cpp.Il2CppType(searchParams)
    if typeStruct.Init then typeStruct:Init() end
    typeStruct.address = searchParams
    
    local types = setmetatable(typeStruct, {
        __index = Type,
        __tostring = Type.ToString,
        __name = "Type"
    })
    Il2Cpp.__cache.Type[searchParams] = types
    return types
end

function Type.GetSimpleName(typeStruct)
    local TypeString = {
        [1] = "void", [2] = "bool", [3] = "char", [4] = "sbyte", [5] = "byte",
        [6] = "short", [7] = "ushort", [8] = "int", [9] = "uint", [10] = "long",
        [11] = "ulong", [12] = "float", [13] = "double", [14] = "string",
        [22] = "TypedReference", [24] = "IntPtr", [25] = "UIntPtr", [28] = "object",
    }
    return TypeString[typeStruct.type or 0] or "Unknown"
end

function Type.GetName(typeStruct, addNamespaze)
    local name = Type.GetSimpleName(typeStruct)
    if name ~= "Unknown" then return name end
    return "object"
end

function Type.ToString(typeStruct)
    return Type.GetName(typeStruct)
end

return setmetatable(Type, {
    __call = Type.From
})
end)

return __bundle_require("Il2CppGG")
