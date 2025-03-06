local IsValid = IsValid

TOOL.Category = "Deformation"
TOOL.Name = "#tool.makedeform.name"
    
    TOOL.Information = {
        { name = "left" },
    }

function TOOL:LeftClick(trace)
    local ent = trace.Entity
    if not IsValid(ent) or ent.IsDEFORMMESH or ent:IsPlayer() then return false end

    local dent = ents.Create("ent_deformmesh")

    dent:SetModel(ent:GetModel())
    dent:SetPos(ent:GetPos())
    dent:SetAngles(ent:GetAngles())
    dent:SetMaterial(ent:GetMaterial())
    dent:SetColor(ent:GetColor())

    dent:Spawn()
    dent:Activate()

    local phys = ent:GetPhysicsObject()
    local phys1 = dent:GetPhysicsObject()

    if IsValid(phys1) and IsValid(phys) then
        phys1:SetMass(phys:GetMass())
        phys1:SetVelocity(phys:GetVelocity())
        phys1:AddAngleVelocity(phys:GetAngleVelocity())
    end

    undo.Create("prop")
        undo.AddEntity(dent)
        undo.SetPlayer(self:GetOwner())
    undo.Finish()

    local ef = EffectData()
        ef:SetEntity(dent)
        ef:SetOrigin(dent:GetPos())
    util.Effect("deformlizer", ef)

    ent:Remove()

    return true
end

function TOOL:RightClick(trace)
    return false
end

function TOOL:Reload(trace)
    return false
end
