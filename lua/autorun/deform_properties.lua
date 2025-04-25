
local properties = properties
local gamemode = gamemode

local IsValid = IsValid

properties.Add( "deform_restore_shape", {
    MenuLabel = "Restore Shape",
    MenuIcon = "icon16/shape_square.png",
    Order = 659,
    Filter = function( self, ent, ply )
        if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, name, ent ) ) then return false end
        if !ent.IsDEFORMMESH then return false end
        return true
    end,

    Action = function( self, ent )
        local MESHMODEL = util.GetModelMeshes(ent:GetModel())[1]
        local mymesh = ent.FromRENDER and MESHMODEL.triangles or ent:GetPhysicsObject():GetMesh()
        
        -- xD goofy fix, that works
        for i = 1, #mymesh do
            local vert = mymesh[i]
            mymesh[i] = {
                normal = vert.normal,
                pos = vert.pos,
                userdata = vert.userdata,
                tangent = vert.tangent,
                u = vert.u,
                v = vert.v,
                weights = vert.weights
            }
        end

        ent.DeformedVertc = mymesh
        ent:GenerateMesh(mymesh)
    end,

    Receive = function( self, length, ply ) end
} )

properties.Add( "deform_subdividemesh", {
    MenuLabel = "Subdivide (EXPERIMENTAL!!!)",
    MenuIcon = "icon16/shape_handles.png",
    Order = 660,
    Filter = function( self, ent, ply )
        if ( !IsValid( ent ) or !gamemode.Call( "CanProperty", ply, name, ent ) ) then return false end
        if !ent.IsDEFORMMESH then return false end
        return true
    end,

    Action = function( self, ent )
        local ply = LocalPlayer()

        local AA = #ent.DeformedVertc

        if AA * 4 > 15000 then ply:ChatPrint( (AA*4).."/15000 - TOO MUCH, WE USE "..AA ) return end

        local mymesh = ent.DeformedVertc or ent:GetPhysicsObject():GetMesh()

        mymesh = ent:SubdivideMesh(mymesh)

        ent:GenerateMesh(mymesh)
        ent.DeformedVertc = mymesh

        ply:ChatPrint( "OLD - ".. AA .." | NEW - ".. #ent.DeformedVertc )
    end,

    Receive = function( self, length, ply ) end
} )
