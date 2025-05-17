AddCSLuaFile()

local mesh = mesh
local math = math
local net = net

local Material = Material
local Vector = Vector
local Mesh = Mesh

local vector_origin = vector_origin
local math_Clamp = math.Clamp
local table_insert = table.insert

local SERVER = SERVER

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Editable = true
ENT.PrintName		= "Deformation"
ENT.Author			= "Ty4a"
ENT.Instructions	= "Do you have any ideas where I can use this?"
ENT.Spawnable = true

ENT.DeformedVertc = {}

--BASA
ENT.IsDEFORMMESH = true
ENT.FromRENDER = false
ENT.MyMESH = nil
ENT.MAT = Material("models/shiny")

local model = IsMounted("cstrike") and "models/props/de_nuke/car_nuke_red.mdl" or "models/props_interiors/Furniture_Couch01a.mdl"

function ENT:SetupDataTables()
    self:NetworkVar( "Float", 0, "RadiusCOEF", { KeyName = "radiuscoef", Edit = { type = "Float", min = 0.1, max = 1, order = 1, title = "Radius Coefficent", category = "Collide"} } )
    self:NetworkVar( "Float", 1, "DamageCOEF", { KeyName = "damagecoef", Edit = { type = "Float", min = 0.01, max = 100, order = 2, title = "Damage Coefficent", category = "Collide"} } )

    self:NetworkVar( "Bool", 0, "SoundTOG", { KeyName = "soundarmatura", Edit = { type = "Bool", order = 3, title = "Toggle Sound", category = "Visual & Sound"} } )
    self:NetworkVar( "Bool", 1, "EffectTOG", { KeyName = "effectarmatura", Edit = { type = "Bool", order = 4, title = "Toggle Effects", category = "Visual & Sound"} } )
    self:NetworkVar( "Int", 0, "SoundTYPE", { KeyName = "soundarmtype", Edit = { type = "Int", min = 1, max = 6, order = 5, title = "Sound Type", category = "Visual & Sound"} } )

    if SERVER then
        self:NetworkVarNotify( "RadiusCOEF", self.SVOptRadiuscoef )
        self:NetworkVarNotify( "DamageCOEF", self.SVOptDamagecoef )
        self:NetworkVarNotify( "SoundTOG", self.SVOptSoundtog )
        self:NetworkVarNotify( "EffectTOG", self.SVOptEffecttog )
        self:NetworkVarNotify( "SoundTYPE", self.SVOptSoundtype )

        self:SetRadiusCOEF(0.2)
        self:SetDamageCOEF(1)
        self:SetSoundTOG(true)
        self:SetEffectTOG(true)
        self:SetSoundTYPE(1)
    end
end

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
    ent:SetAngles( SpawnAng )
	ent:SetModel( model )
	ent:Spawn()
	ent:Activate()

    ent:GetPhysicsObject():SetMass(250)

	return ent
end

function ENT:Initialize()

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysWake()

    local obbmax, oobmin = self:OBBMaxs(), self:OBBMins()
    self.MYSIZEOBB = math_Clamp( ( obbmax - oobmin ):Length() , 1 , 150 )

    if CLIENT then
        local MESHMODEL = util.GetModelMeshes(self:GetModel())[1]
        local mymesh = self.MyMESH or (self.FromRENDER and MESHMODEL.verticies or self:GetPhysicsObject():GetMesh())
        self:UPDATEMAT()

        self:GenerateMesh(mymesh)
        self.DeformedVertc = mymesh
        self:SetRenderBounds(oobmin, obbmax)

        --print(#mymesh)
    end
end

function ENT:UPDATEMAT()
    local MESHMODEL = util.GetModelMeshes(self:GetModel())[1]
    self.MAT = self.FromRENDER and Material(MESHMODEL.material) or mat
end

if SERVER then 
    util.AddNetworkString("Deformation_Apply")

    function ENT:OnTakeDamage(dmginfo)
        local dmg = dmginfo:GetDamage()
        net.Start("Deformation_Apply")
            net.WriteEntity(self)
            net.WriteVector(dmginfo:GetDamagePosition())
            local net_WriteFloat = net.WriteFloat
            net_WriteFloat(math.min(dmg, 15))
            net_WriteFloat(dmg)
        net.Broadcast()
    end

    function ENT:PhysicsCollide(data, phys)
        if data.DeltaTime <= 0.1 then return end

        local speed = data.Speed
        if speed >= 150 then

            local hitpos = data.HitPos
            
            if self.SVEffectTog then
                local ef = EffectData()
                    ef:SetEntity(self)
                    ef:SetOrigin(hitpos)
                    ef:SetNormal(data.HitNormal)
                util.Effect("cardamage_a", ef)
            end

            local math_random = math.random

            if self.SVSoundTog then
                local sound = self.SVSoundType .. math_random(1, 3) .. ".wav"
                self:EmitSound(sound, 75, math_random(75, 150), speed * 0.1)
            end

            net.Start("Deformation_Apply")
                net.WriteEntity(self)
                net.WriteVector(hitpos)

                local net_WriteFloat = net.WriteFloat

                local coef = self.SVDamagecoef
                net_WriteFloat(math.min(speed * 0.005 * coef, 20 * coef))
                net_WriteFloat(self.MYSIZEOBB * self.SVRadiuscoef)
            net.Broadcast()
        end
    end

    function ENT:Use(v)
        local phys = self:GetPhysicsObject()
        if phys:GetMass() > 35 then return end

        if v:IsPlayer() then
            if self:IsPlayerHolding() then return end
            v:PickupObject(self)
        end
    end

    local sss = {
        [1] = "physics/metal/metal_canister_impact_soft",
        [2] = "physics/metal/metal_chainlink_impact_hard",
        [3] = "physics/metal/metal_computer_impact_hard",
        [4] = "physics/metal/metal_barrel_impact_hard",
        [5] = "physics/metal/metal_sheet_impact_hard",
        [6] = "physics/metal/metal_solid_impact_bullet"
    }

    function ENT:SVOptSoundtype(_, oldvalue, newvalue)
        if ( oldvalue == newvalue ) then return end

        self.SVSoundType = sss[newvalue]
    end

    function ENT:SVOptSoundtog(_, oldvalue, newvalue)
        if ( oldvalue == newvalue ) then return end

        self.SVSoundTog = newvalue
    end

    function ENT:SVOptEffecttog(_, oldvalue, newvalue)
        if ( oldvalue == newvalue ) then return end

        self.SVEffectTog = newvalue
    end

    function ENT:SVOptRadiuscoef(_, oldvalue, newvalue)
        if ( oldvalue == newvalue ) then return end

        self.SVRadiuscoef = newvalue
    end

    function ENT:SVOptDamagecoef(_, oldvalue, newvalue)
        if ( oldvalue == newvalue ) then return end

        self.SVDamagecoef = newvalue
    end

end

if SERVER then return end


local meta = FindMetaTable("Entity")
ENT.Draw = meta.DrawModel

local metavec = FindMetaTable("Vector")
local GetNormalized = metavec.GetNormalized
local Cross = metavec.Cross
local DistToSqr = metavec.DistToSqr

local function generateUV(vertices, scale)

    local function calculateUV(vertex, normal)
        local pos = vertex.pos
        vertex.u = pos.x * scale
        vertex.v = pos.y * scale
    end

    for i = 1, #vertices - 2, 2 do
        local a, b, c = vertices[i], vertices[i + 1], vertices[i + 2]

        local apos = a.pos

        local normal = GetNormalized(Cross(b.pos - apos, c.pos - apos))

        calculateUV(a, normal)
        calculateUV(b, normal)
        calculateUV(c, normal)
    end

    return vertices
end

local function generateNormals(vertices)
    local v = vector_origin
    local cross = v.cross or v.Cross
    local normalize = v.normalize or v.Normalize
    local dot = v.dot or v.Dot
    local add = v.add or v.Add
    local div = v.div or v.Div
    local org = cross

    cross = function(a, b)
        return org(b, a)
    end
    
    for i = 1, #vertices - 2, 3 do
        local a, b, c = vertices[i], vertices[i + 1], vertices[i + 2]

        local apos = a.pos
        local norm = cross(b.pos - apos, c.pos - apos)
        normalize(norm)
        
        a.normal = norm
        b.normal = norm
        c.normal = norm
    end

end

net.Receive("Deformation_Apply", function()
    local hitent = net.ReadEntity()
    local hitPos = net.ReadVector()

    local net_ReadFloat = net.ReadFloat

    local strength = net_ReadFloat()
    local radius = net_ReadFloat()
    radius = radius * radius

    local localpos = hitent:WorldToLocal(hitPos)
    local shitpos = GetNormalized(-localpos) * strength
    local vertices = hitent.DeformedVertc

    for i = 1, #vertices do
        local vertex = vertices[i]
        local pos = vertex.pos
        local distance = DistToSqr(pos, localpos)

        if distance < radius then
            local distance2 = 1 - (distance / radius)
            vertex.pos = pos + shitpos * distance2
        end
    end

    hitent:GenerateMesh(vertices)
end)

local metamesh = FindMetaTable("IMesh")
local BuildFromTriangles = metamesh.BuildFromTriangles

function ENT:GenerateMesh(mesh)
    if !self.FromRENDER then 
        mesh = generateUV(mesh, 0.01, Vector, Angle, WorldToLocal)
        generateNormals(mesh)
    end
    
    self.RENDER_MESH = Mesh()

    BuildFromTriangles(self.RENDER_MESH, mesh)
end

local mat = Material("models/shiny")

function ENT:GetRenderMesh()
    if !self.RENDER_MESH then return end

    return { Mesh = self.RENDER_MESH, Material = self.MAT or mat }
end

function ENT:SubdivideMesh(vertices)
    local shitverts = {}
    local fromRENDER = self.FromRENDER 

    local function SUB(v1, v2)
        -- xD goofy fix, that works

        if !fromRENDER then return { pos = (v1.pos + v2.pos) / 2 } end
        
        return {
            pos = (v1.pos + v2.pos) / 2,
            normal = GetNormalized(((v1.normal + v2.normal) / 2)),
            tangent = ((v1.tangent or vector_origin) + (v2.tangent or vector_origin)) / 2,
            u = ((v1.u or 0) + (v2.u or 0)) / 2,
            v = ((v1.v or 0) + (v2.v or 0)) / 2,
            userdata = (v2.userdata or 0 + v2.userdata or 0)
        }
    end

    for i = 1, #vertices, 3 do
        local v1, v2, v3 = vertices[i], vertices[i+1], vertices[i+2]

        local subAB = SUB(v1, v2)
        local subBC = SUB(v2, v3)
        local subCA = SUB(v3, v1)

        shitverts[#shitverts + 1] = subAB
        shitverts[#shitverts + 1] = subBC
        shitverts[#shitverts + 1] = subCA
        shitverts[#shitverts + 1] = v1
        shitverts[#shitverts + 1] = subAB
        shitverts[#shitverts + 1] = subCA
        shitverts[#shitverts + 1] = subAB
        shitverts[#shitverts + 1] = v2
        shitverts[#shitverts + 1] = subBC
        shitverts[#shitverts + 1] = subCA
        shitverts[#shitverts + 1] = subBC
        shitverts[#shitverts + 1] = v3
    end

    -- hate
    for i = 1, #shitverts do
        local vert = shitverts[i]
        shitverts[i] = {
            normal = vert.normal,
            pos = vert.pos,
            userdata = vert.userdata,
            tangent = vert.tangent,
            u = vert.u,
            v = vert.v,
            weights = vert.weights
        }
    end

    return shitverts
end