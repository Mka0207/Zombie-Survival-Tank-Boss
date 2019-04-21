INC_SERVER()

local function ThrowThatRock(pl, wep)
	if pl:IsValid() and pl:Alive() and wep:IsValid() then
		--pl:ResetSpeed()
		pl.LastRangedAttack = CurTime()

		local startpos = pl:GetPos()
		startpos.z = pl:GetShootPos().z
		local heading = pl:GetAimVector()

		local ent = ents.Create("projectile_tankrock")
		if ent:IsValid() then
			ent:SetPos(startpos + heading * 45)
			ent:SetAngles(wep:IsMoaning() and Angle(0, -45, -90) or Angle(-90, 0, 0))
			ent:SetOwner(pl)
			ent.Damage = wep:IsMoaning() and 132 or 66
			ent:Spawn()

			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetVelocityInstantaneous(heading * (wep:IsMoaning() and 3000 or 1500))
				phys:AddAngleVelocity(VectorRand() * (wep:IsMoaning() and 300 or 150))
			end
		end

		--pl:RawCapLegDamage(CurTime() + 2)
		pl:EmitSound("npc/zombie/claw_miss"..math.random(2)..".wav", 75, wep:IsMoaning() and 35 or 50)
		pl:SetBodygroup( 1, 0 )
		pl:ResetJumpPower()
	end
end

SWEP.MoanDelay = 0.5
function SWEP:Reload()
	if CurTime() < self:GetNextSecondaryFire() then return end
	self:SetNextSecondaryFire(CurTime() + self.MoanDelay)

	if self:IsMoaning() then
		self:StopMoaning()
	else
		self:StartMoaning()
	end
end

SWEP.RockThrowDelay = 3
function SWEP:SecondaryAttack()
	if CLIENT then return end
	local owner = self:GetOwner()
	
	local entfilter = {
		"prop_physics",
		"prop_physics_override",
		"prop_dynamic"
	}

	local tr = util.TraceHull( {
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos(),
		filter = function(ent) if (ent:GetClass() == entfilter) then return true end end,
		mins = Vector( -70, -70, -70 ),
		maxs = Vector( 70, 70, 70 )
	} )

	if tr.Hit then return end
	if not owner:OnGround() or self:IsSwinging() or self:IsInAttackAnim() or self:GetIsThrowing() then return end
	if self:GetNextSecondaryFire() > CurTime() then return end

	self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

	self.RockThrowDelay = self:IsMoaning() and 2.95 or 1.45

	self:SetIsThrowing(true)
	owner:SetSpeed(1)
	owner:SetJumpPower(0)
	owner:SetLocalVelocity(owner:GetVelocity() * 0)

	self:PlayAttackSound()
	owner:SetBodygroup( 1, 1 )

	if self.GetThrowingRockStart and self:GetThrowingRockStart() then
		self:SetThrowingRockStart( CurTime() + self.RockThrowDelay )
	end

	timer.Simple(self:IsMoaning() and 0.25 or 0, function()
		if IsValid( self:GetOwner() ) and self:GetOwner():Alive() and self:GetOwner():GetActiveWeapon() == self.Weapon then
			owner:EmitSound("physics/concrete/concrete_break2.wav", 75, self:IsMoaning() and 35 or 50)
		end
	end)

	timer.Simple(self.RockThrowDelay - 0.5, function()
		if IsValid( self:GetOwner() ) and self:GetOwner():Alive() and self:GetOwner():GetActiveWeapon() == self.Weapon then
			ThrowThatRock(owner, self)
		end
	end)

	timer.Simple(self.RockThrowDelay, function()
		if IsValid( self:GetOwner() ) and self:GetOwner():Alive() and self:GetOwner():GetActiveWeapon() == self.Weapon then
			self:SetThrowingRockStart(0)
			if not self:IsMoaning() then
				owner:ResetSpeed()
			else
				owner:SetSpeed( owner:GetZombieClassTable().RunSpeed )
			end

			self:SetIsThrowing(false)
		end
	end)
end
