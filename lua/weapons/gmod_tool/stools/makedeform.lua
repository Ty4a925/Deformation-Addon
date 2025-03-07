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
        net.Start("Deformation_FromRENDER")
            net.WriteEntity(dent)
        net.Broadcast()
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

    SafeRemoveEntity(ent)

    return dent
end

function TOOL:LeftClick(trace)
    local ent = trace.Entity
    if not IsValid(ent) or ent.IsDEFORMMESH or ent:IsPlayer() then return false end

    local dent = MAKEDEFORMA(self:GetOwner(), ent, false)

    return true
end

function TOOL:RightClick(trace)
    local ent = trace.Entity
    if not IsValid(ent) or ent.IsDEFORMMESH or ent:IsPlayer() then return false end

    local dent = MAKEDEFORMA(self:GetOwner(), ent, true)

    return true
end

function TOOL:Reload(trace)
    return false
end
