local math = math

local math_rand = math.Rand
local math_random = math.random

function EFFECT:Init(data)
    
    local GRAVITY = Vector(0, 0, GetConVarNumber("sv_gravity"))

    self.CarEnt = data:GetEntity()
    self.Normal = data:GetNormal()
    self.Position = data:GetOrigin()

    local AddVel = self.CarEnt:GetPhysicsObject():GetVelocity()
	
	local emitter = ParticleEmitter(self.Position)

        local pospos = self.CarEnt:GetPos()
		local physmesh = self.CarEnt.DeformedVertc
		for _, vertex in ipairs(physmesh) do
			local vertpos = vertex.pos

			local particle = emitter:Add("sprites/blueglow2", pospos+vertpos )

			particle:SetVelocity( (self.CarEnt:WorldToLocal(pospos) + vertpos):GetNormalized()*225 )
			particle:SetAirResistance( 0 )

			particle:SetGravity(-GRAVITY*0.5)
			particle:SetCollide(1)
			particle:SetBounce(1)

			particle:SetDieTime( 1 )

			particle:SetStartAlpha( 25 )
			particle:SetEndAlpha( 0 )

			particle:SetStartSize( 0.1 )
			particle:SetEndSize( 15 )

			particle:SetRoll( math_rand( -25, 25 ) )
			particle:SetRollDelta( math_rand( -0.05, 0.05 ) )
		end

		emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end