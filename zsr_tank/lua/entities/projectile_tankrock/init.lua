INC_SERVER()

function ENT:Initialize()
	self:SetModel("models/props_debris/concrete_chunk01a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	self:SetCustomCollisionCheck(true)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetMass(20)
		phys:EnableMotion(true)
		phys:Wake()
	end
end

function ENT:Think()
	if self.PhysicsData then
		self:Hit(self.PhysicsData.HitPos, self.PhysicsData.HitNormal, self.PhysicsData.HitEntity)
	end

	if self.Exploded then
		self:Remove()
	end
end

function ENT:Hit(vHitPos, vHitNormal, ent)
	if self.Exploded then return end
	timer.Simple( 3, function() self.Exploded = true end )

	local owner = self:GetOwner()
	if not owner:IsValid() then owner = self end

	vHitPos = vHitPos or self:GetPos()
	vHitNormal = vHitNormal or Vector(0, 0, 1)

	if ent:IsValid() then
		if ent:IsPlayer() and ent:Team() ~= TEAM_UNDEAD then
			ent:TakeSpecialDamage((self.Damage or 66) * (ent.PhysicsDamageTakenMul or 1), DMG_GENERIC, owner, self)
			ent:GiveStatus("knockdown", 5)
			self.Exploded = true

			local effectdata = EffectData()
				effectdata:SetOrigin(vHitPos)
				effectdata:SetNormal(vHitNormal)
			util.Effect("hit_stone", effectdata)
			util.Effect("hit_tankstone", effectdata)
		elseif ent:GetMoveType() == MOVETYPE_VPHYSICS then
			ent:TakeSpecialDamage((self.Damage or 66) * (ent.PhysicsDamageTakenMul or 1), DMG_GENERIC, owner, self)
			self.Exploded = true

			local effectdata = EffectData()
				effectdata:SetOrigin(vHitPos)
				effectdata:SetNormal(vHitNormal)
			util.Effect("hit_stone", effectdata)
			util.Effect("hit_tankstone", effectdata)
		end
	end
end

function ENT:PhysicsCollide(data, phys)
	self.PhysicsData = data

	self:EmitSound("physics/concrete/concrete_break2.wav", 77, 70)

	self:NextThink(CurTime())
end
