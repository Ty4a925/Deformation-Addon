local gravity_convar = GetConVar("sv_gravity")

function EFFECT:Init(data)
	local car = data:GetEntity()
	local gravity = Vector(0, 0, gravity_convar:GetInt())
	local emitter = ParticleEmitter(self.Position)
	local carpos = car:GetPos()

	for _, vertex in ipairs(car.DeformedVertc) do
		local particle = emitter:Add("sprites/blueglow2", carpos + vertex.pos)
		particle:SetVelocity((car:WorldToLocal(carpos) + vertex.pos):GetNormalized() * 225)
		particle:SetAirResistance(0)
		particle:SetGravity(-gravity * 0.5)
		particle:SetCollide(1)
		particle:SetBounce(1)
		particle:SetDieTime(1)
		particle:SetStartAlpha(25)
		particle:SetEndAlpha(0)
		particle:SetStartSize(0.1)
		particle:SetEndSize(15)
		particle:SetRoll(math.Rand(-25, 25))
		particle:SetRollDelta(math.Rand(-0.05, 0.05))
	end

	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()

end