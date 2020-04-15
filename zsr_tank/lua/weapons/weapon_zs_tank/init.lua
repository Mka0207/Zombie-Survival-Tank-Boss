INC_SERVER()

function SWEP:ThrowThatRock()
	local pl = self:GetOwner()
	if pl:IsValid() and pl:Alive() then
		pl.LastRangedAttack = CurTime()

		local startpos = pl:GetPos()
		startpos.z = pl:GetShootPos().z
		local heading = pl:GetAimVector()

		local ent = ents.Create("projectile_tankrock")
		if ent:IsValid() then
			ent:SetPos(startpos + heading * 45)
			ent:SetAngles(self:IsMoaning() and Angle(0, -45, -90) or Angle(-90, 0, 0))
			ent:SetOwner(pl)
			ent.Damage = self:IsMoaning() and 70 or 50
			ent:Spawn()

			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				if not GAMEMODE:IsHvH() then
					phys:SetVelocityInstantaneous(heading * (self:IsMoaning() and 2000 or 1500))
					phys:AddAngleVelocity(VectorRand() * (self:IsMoaning() and 300 or 150))
				else
					phys:SetVelocityInstantaneous(heading * (self:IsMoaning() and 4500 or 3500))
					phys:AddAngleVelocity(VectorRand() * (self:IsMoaning() and 300 or 150))
				end
			end
		end

		pl:EmitSound("npc/zombie/claw_miss"..math.random(2)..".wav", 75, self:IsMoaning() and 35 or 50)
		pl:SetBodygroup( 1, 0 )
		pl:ResetJumpPower()
	end
end

function SWEP:FinishThrow()
	self:SetThrowingRockStart(0)
	
	local owner = self:GetOwner()
	if not self:IsMoaning() then
		owner:ResetSpeed()
	else
		owner:SetSpeed( GAMEMODE.ZombieClasses["Tank"].RunSpeed )
	end

	self:SetIsThrowing(false)
end

SWEP.MoanDelay = 0.5
function SWEP:Reload()
	if CurTime() < self:GetNextSecondaryFire() or self:GetThrowingRockStart() > CurTime() then return end
	self:SetNextSecondaryFire(CurTime() + self.MoanDelay)

	if self:IsMoaning() then
		self:StopMoaning()
	else
		self:StartMoaning()
	end
end

function SWEP:SecondaryAttack()
	local owner = self:GetOwner()
	local entfilter = {
		"prop_physics",
		"prop_physics_multiplayer",
		"prop_physics_override",
		"prop_dynamic"
	}
	local tr = util.TraceHull( {
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos(),
		filter = function(ent) if (ent:GetClass() == entfilter) then return true end end,
		mins = Vector( -50, -50, -50 ),
		maxs = Vector( 50, 50, 50 )
	} )

	if tr.Hit then return end
	if not owner:OnGround() or self:IsSwinging() or self:IsInAttackAnim() or self:GetIsThrowing() then return end
	if self:GetNextSecondaryFire() > CurTime() then return end
	
	self.Secondary.Delay = self:IsMoaning() and 2.95 or 1.45
	self:SetNextSecondaryFire(CurTime() + ( self.Secondary.Delay + 3 ) )
	self:SetIsThrowing(true)
	self:PlayAttackSound()
	
	owner:SetSpeed(1)
	owner:SetJumpPower(0)
	owner:SetLocalVelocity(owner:GetVelocity() * 0)
	owner:SetBodygroup( 1, 1 )
	
	if self.GetThrowingRockStart and self:GetThrowingRockStart() then
		self:SetThrowingRockStart( CurTime() + self.Secondary.Delay )
	end
	timer.Simple( self.Secondary.Delay - 0.5, function()
		if not ( self and self:IsValid() ) then return end
		self:ThrowThatRock() 
	end )
	timer.Simple(self.Secondary.Delay, function()
		if not ( self and self:IsValid() ) then return end
		self:FinishThrow()
	end)
end
