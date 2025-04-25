AddCSLuaFile()

local IsValid = IsValid

TOOL.Category = "Deformation"
TOOL.Name = "#tool.makedeform.name"
    
TOOL.Information = {
    { name = "left" },
    { name = "right" }
}

if SERVER then
    util.AddNetworkString("Deformation_FromRENDER")
else
    -- спешка
    net.Receive("Deformation_FromRENDER", function()
        local hitent = net.ReadEntity()

        hitent.FromRENDER = true
        local MESHMODEL = util.GetModelMeshes(hitent:GetModel())[1]
        local mymesh = hitent.MyMESH or (hitent.FromRENDER and MESHMODEL.triangles or hitent:GetPhysicsObject():GetMesh())

        --PrintTable(mymesh)
        -- xD goofy fix, that works
        -- TODO:FUCK
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

        hitent:GenerateMesh(mymesh)
        hitent.DeformedVertc = mymesh
        hitent:UPDATEMAT()
    end)
end

local function MAKEDEFORMA(ply, ent, bool)
    local dent = ents.Create("ent_deformmesh")

    dent:SetModel(ent:GetModel())
    dent:SetPos(ent:GetPos())
    dent:SetAngles(ent:GetAngles())
    dent:SetMaterial(ent:GetMaterial())
    dent:SetColor(ent:GetColor())

    dent:Spawn()
    dent:Activate()

    if bool then
        timer.Simple(0, function()
            net.Start("Deformation_FromRENDER")
                net.WriteEntity(dent)
            net.Broadcast()
        end)
    end

    local phys = ent:GetPhysicsObject()
    local phys1 = dent:GetPhysicsObject()

    if IsValid(phys1) and IsValid(phys) then
        phys1:SetMass(phys:GetMass())
        phys1:SetVelocity(phys:GetVelocity())
        phys1:AddAngleVelocity(phys:GetAngleVelocity())
    end

    undo.Create("prop")
        undo.AddEntity(dent)
        undo.SetPlayer(ply)
    undo.Finish()

    /*local ef = EffectData()
        ef:SetEntity(dent)
        ef:SetOrigin(dent:GetPos())
    util.Effect("deformlizer", ef)*/

    SafeRemoveEntity(ent)

    return dent
end

function TOOL:LeftClick(trace)
    local ent = trace.Entity
    if not IsValid(ent) or ent.IsDEFORMMESH or ent:IsPlayer() then return false end

    if SERVER then
        MAKEDEFORMA(self:GetOwner(), ent, false)
    end

    return true
end

function TOOL:RightClick(trace)
    local ent = trace.Entity
    if not IsValid(ent) or ent.IsDEFORMMESH or ent:IsPlayer() then return false end

    if SERVER then
        MAKEDEFORMA(self:GetOwner(), ent, true)
    end

    return true
end

function TOOL:Reload(trace)
    return false
end
