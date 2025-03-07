local color_smoke = Color(200, 200, 200)
local gravity_convar = GetConVar("sv_gravity")

function EFFECT:Init(data)
    local normal = data:GetNormal()
    local pos = data:GetOrigin()

	local gravity = Vector(0, 0, gravity_convar:GetInt())
	local particlepos = pos - normal * 5
	local emitter = ParticleEmitter(pos)

	for i = 1, 5 do
		local particle = emitter:Add("particle/smokesprites_000" .. math.random(1, 8), particlepos)
		particle:SetVelocity(normal * -math.Rand(100, 255) - VectorRand(-55, 55))
		particle:SetAirResistance(0)
		particle:SetGravity(gravity * 0.2)
		particle:SetCollide(1)
		particle:SetDieTime(math.Rand(0.3, 0.6))
		particle:SetStartAlpha(100)
		particle:SetEndAlpha(0)
		particle:SetStartSize(math.Rand(0, 5))
		particle:SetEndSize(math.Rand(50, 100))
		particle:SetRoll(math.Rand(-25, 25))
		particle:SetRollDelta(math.Rand(-0.05, 0.05))
		particle:SetColor(color_smoke)
	end

	local particle = emitter:Add("sprites/rico1", pos)
	particle:SetAirResistance(0)
	particle:SetCollide(0)
	particle:SetDieTime(math.Rand(0.05, 0.1))
	particle:SetStartAlpha(25)
	particle:SetEndAlpha(0)
	particle:SetStartSize(math.Rand(1, 5))
	particle:SetEndSize(8)
	particle:SetRoll(math.Rand(-25, 25))
	particle:SetRollDelta(math.Rand(-0.05, 0.05))

	for i = 1, 5 do
		local particle = emitter:Add("sprites/orangecore2", particlepos)
		particle:SetVelocity(normal * -math.Rand(25, 150) - VectorRand(-55, 55))
		particle:SetDieTime(math.Rand(1, 5))
		particle:SetStartSize(math.Rand(0.5, 1))
		particle:SetEndSize(1)
		particle:SetGravity(-gravity)
		particle:SetCollide(1)
		particle:SetBounce(math.Rand(0.1, 0.7))
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