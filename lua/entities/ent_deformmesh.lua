AddCSLuaFile()

local mesh = mesh
local math = math
local net = net

local ipairs = ipairs
local Vector = Vector
local Mesh = Mesh

local vector_origin = vector_origin
local math_Clamp = math.Clamp
local table_insert = table.insert

local SERVER = SERVER

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName		= "Deformation"
ENT.Author			= "Ty4a"
ENT.Instructions	= "Do you have any ideas where I can use this?"
ENT.Spawnable = true

ENT.DeformedVertc = {}

--BASA
ENT.IsDEFORMMESH = true
ENT.MyMESH = nil

function ENT:SpawnFunction( ply, tr, ClassName )
	if ( !tr.Hit ) then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 16
    local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180

	local ent = ents.Create( ClassName )
	ent:SetPos( SpawnPos )
    ent:SetAngles( SpawnAng )
	ent:SetModel("models/props/de_nuke/car_nuke_red.mdl")
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
    self.MYSIZEOBB = math_Clamp( ( obbmax - oobmin ):Length() , 1 , 50 )

    if CLIENT then
        local mymesh = self.MyMESH or self:GetPhysicsObject():GetMesh()

        self:GenerateMesh(mymesh)
        self.DeformedVertc = mymesh
        self:SetRenderBounds(oobmin, obbmax)

        --print(#mymesh)
    end
end

if SERVER then 
    util.AddNetworkString("Deformation_Apply")

    function ENT:OnTakeDamage(dmginfo)
        local dmg = dmginfo:GetDamage()
        net.Start("Deformation_Apply")
            net.WriteEntity(self)
            net.WriteVector(dmginfo:GetDamagePosition())
            net.WriteNormal(-dmginfo:GetDamageForce())
            local net_WriteFloat = net.WriteFloat
            net_WriteFloat(math.min(dmg,15))
            net_WriteFloat(dmg)
        net.Broadcast()
    end

    function ENT:PhysicsCollide(data, phys)
        if data.DeltaTime > 0.1 then
            local speed = data.Speed
            if speed >= 150 then
                local ef = EffectData()
                    ef:SetEntity(self)
                    ef:SetOrigin(data.HitPos)
                    ef:SetNormal(data.HitNormal)
                util.Effect("cardamage_a", ef)

                local math_random = math.random

                local sound = "physics/metal/metal_canister_impact_soft" .. math_random(1, 3) .. ".wav"
                self:EmitSound(sound, 75, math_random(75, 150), speed*0.1)

                local impactForce = speed * phys:GetMass()

                local velocity = self:GetVelocity() or vector_origin
                local nv = velocity:GetNormalized()

                net.Start("Deformation_Apply")
                    net.WriteEntity(self)
                    net.WriteVector(data.HitPos)
                    net.WriteNormal(nv)
                    local net_WriteFloat = net.WriteFloat
                    net_WriteFloat(math.min(speed*0.005,10))
                    net_WriteFloat(self.MYSIZEOBB)
                net.Broadcast()
            end
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

end

if SERVER then return end

local function generateUV(vertices, scale)

    local function calculateUV(vertex, normal)
        vertex.u = vertex.pos.x * scale
        vertex.v = vertex.pos.y * scale
    end

    for i = 1, #vertices - 2, 2 do
        local a, b, c = vertices[i], vertices[i + 1], vertices[i + 2]

        local apos = a.pos

        local normal = (b.pos - apos):Cross(c.pos - apos):GetNormalized()

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

local mat = Material("models/shiny")

net.Receive("Deformation_Apply", function()
    local hitent = net.ReadEntity()
    local hitPos = net.ReadVector()
    local hitNormal = net.ReadNormal()
    local net_ReadFloat = net.ReadFloat
    local strength = net_ReadFloat()
    local radius = net_ReadFloat()

    local worldlocal = hitent:WorldToLocal(hitPos)

    local DEFORMED_VERTICES = hitent.DeformedVertc

    for I=1, #DEFORMED_VERTICES do
        local vertex = DEFORMED_VERTICES[I]
        local vertpos = vertex.pos
        local dist = vertpos:Distance(worldlocal)
        if dist < radius then
            local direction = (vertpos + worldlocal):GetNormalized() + hitNormal
            local distance3 = math_Clamp(1 - (dist / radius), 0, 1)

            local direction2 = direction * strength * distance3

            vertex.pos = vertpos - direction2
        end
    end

    hitent:GenerateMesh(DEFORMED_VERTICES)
end)

function ENT:GenerateMesh(mesh)
    mesh = generateUV(mesh, 0.05, Vector, Angle, WorldToLocal)
    generateNormals(mesh)
    
    self.RENDER_MESH = Mesh()
    self.RENDER_MESH:BuildFromTriangles(mesh)
end

function ENT:GetRenderMesh()
    if !self.RENDER_MESH then return end
    return { Mesh = self.RENDER_MESH, Material = mat }
end

function ENT:SubdivideMesh(vertices)
    local newVertices = {}

    local function SUB(v1, v2)
        return {
            pos = (v1.pos + v2.pos) / 2
        }
    end

    for i = 1, #vertices, 3 do
        local v1, v2, v3 = vertices[i], vertices[i+1], vertices[i+2]

        local subAB = SUB(v1, v2)
        local subBC = SUB(v2, v3)
        local subCA = SUB(v3, v1)

        table_insert(newVertices, subAB)
        table_insert(newVertices, subBC)
        table_insert(newVertices, subCA)
        table_insert(newVertices, v1)
        table_insert(newVertices, subAB)
        table_insert(newVertices, subCA)
        table_insert(newVertices, subAB)
        table_insert(newVertices, v2)
        table_insert(newVertices, subBC)
        table_insert(newVertices, subCA)
        table_insert(newVertices, subBC)
        table_insert(newVertices, v3)
    end

    return newVertices
end