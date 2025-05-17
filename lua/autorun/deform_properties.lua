local properties = properties
local gamemode = gamemode
local IsValid = IsValid

local MAXVERTC = 15000

properties.Add("deform_restore_shape", {
    MenuLabel = "Restore Shape",
    MenuIcon = "icon16/shape_square.png",
    Order = 659,

    Filter = function(self, ent, ply)
        if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, "deform_restore_shape", ent ) ) then return false end
        if !ent.IsDEFORMMESH then return false end
        return true
    end,

    Action = function(self, ent)
        local meshdata = util.GetModelMeshes(ent:GetModel())[1]
        local base = ent.FromRENDER and meshdata.triangles or ent:GetPhysicsObject():GetMesh()

        for i = 1, #base do
            local v = base[i]
            base[i] = {
                pos = v.pos,
                normal = v.normal,
                userdata = v.userdata,
                tangent = v.tangent,
                u = v.u,
                v = v.v,
                weights = v.weights
            }
        end

        ent.DeformedVertc = base
        ent:GenerateMesh(base)
    end,

    Receive = function(self, length, ply) end
})

-- lua/autorun/properties/skin.lua CODE
properties.Add("deform_subdividemesh", {
    MenuLabel = "Subdivide",
    MenuIcon = "icon16/shape_handles.png",
    Order = 660,

    Filter = function(self, ent, ply)
        if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, "deform_subdividemesh", ent ) ) then return false end
        if !ent.IsDEFORMMESH then return false end
        return true
    end,

    MenuOpen = function(self, option, ent)
        local verts = ent.DeformedVertc or {}
        local count = #verts
        if count * 4 > MAXVERTC then return end
        local submenu = option:AddSubMenu()

        local ply = LocalPlayer()

        for i = 1, 5 do
            local count2 = count * (4 ^ i)
            if count2 > MAXVERTC then return end

            local opt = submenu:AddOption("Subdivide x".. i .." (" .. count2 .. " verts)")
            opt.DoClick = function()
                for j = 1, i do
                    verts = ent:SubdivideMesh(verts)
                    if #verts > MAXVERTC then return end
                end
                ent.DeformedVertc = verts
                ent:GenerateMesh(verts)

                ply:ChatPrint("OLD: " .. count .. " | NEW: " .. #verts)
            end
        end
    end,

    Action = function(self, ent)
        local ply = LocalPlayer()
        local verts = ent.DeformedVertc
        local count = #verts

        if count * 4 > MAXVERTC then
            ply:ChatPrint((count * 4) .. "/"..MAXVERTC.." - TOO MUCH, WE USE " .. count)
            return
        end

        local mesh = ent:SubdivideMesh(verts)
        ent.DeformedVertc = mesh
        ent:GenerateMesh(mesh)

        ply:ChatPrint("OLD: " .. count .. " | NEW: " .. #mesh)
    end,

    Receive = function(self, length, ply) end
})