local math = math

local math_rand = math.Rand
local math_random = math.random
local color_grSMOKE = Color(200, 200, 200)

function EFFECT:Init(data)
    
    local GRAVITY = Vector(0, 0, GetConVarNumber("sv_gravity"))

    self.CarEnt = data:GetEntity()
    self.Normal = data:GetNormal()
    self.Position = data:GetOrigin()

    local AddVel = self.CarEnt:GetPhysicsObject():GetVelocity()
	
	local emitter = ParticleEmitter(self.Position)

		for i=1, 5 do
			local particle = emitter:Add( "particle/smokesprites_000"..math_random(1,8), self.Position - self.Normal * 5 )

			particle:SetVelocity( self.Normal * -math_rand(100,255) - VectorRand() * 55 )
			particle:SetAirResistance( 0 )

			particle:SetGravity( GRAVITY * 0.2 )
			particle:SetCollide(1)

			particle:SetDieTime( math_rand(0.3, 0.6) )

			particle:SetStartAlpha( 100 )
			particle:SetEndAlpha( 0 )

			particle:SetStartSize( math_rand( 0, 5 ) )
			particle:SetEndSize( math_rand( 50, 100 ) )

			particle:SetRoll( math_rand( -25, 25 ) )
			particle:SetRollDelta( math_rand( -0.05, 0.05 ) )

			particle:SetColor( color_grSMOKE )
		end

		local particle = emitter:Add("sprites/rico1", self.Position )

		particle:SetAirResistance( 0 )

		particle:SetCollide(0)

		particle:SetDieTime( math_rand(0.05, 0.1) )

		particle:SetStartAlpha( 25 )
		particle:SetEndAlpha( 0 )

		particle:SetStartSize( math_rand( 1, 5 ) )
		particle:SetEndSize( 8 )

		particle:SetRoll( math_rand( -25, 25 ) )
		particle:SetRollDelta( math_rand( -0.05, 0.05 ) )

		for i = 1, 5 do
			local particle = emitter:Add("sprites/orangecore2", self.Position - self.Normal * 5 )

			particle:SetVelocity( self.Normal * -math_rand(25,150) - VectorRand() * 55 )
			particle:SetDieTime( math_rand(1, 5) )

			particle:SetStartSize( math_rand(0.5, 1) )
			particle:SetEndSize(1)

			particle:SetGravity( -GRAVITY )

			particle:SetCollide(1)
			particle:SetBounce( math_rand(0.1, 0.7) )

			particle:SetAirResistance(0.5)
			particle:SetStartLength(0.2)
			particle:SetEndLength(0)
			particle:SetVelocityScale(1)

		end

		emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end