if not gamemode.Get("zombiesurvival") then return end

SWEP.Base = "weapon_zs_zombie"

SWEP.PrintName = "Claws"

SWEP.MeleeReach = 65
SWEP.MeleeDamage = 48
SWEP.MeleeForceScale = 5
SWEP.MeleeSize = 4.5
SWEP.MeleeDamageType = DMG_SLASH
SWEP.Primary.Delay = 1.5
SWEP.Primary.Automatic = false

SWEP.Secondary.Delay = 3
SWEP.Secondary.Automatic = false

AccessorFuncDT(SWEP, "AttackAnimTime", "Float", 2)

function SWEP:Think()
	self:CheckIdleAnimation()
	self:CheckAttackAnimation()
	--self:CheckMoaning()
	self:CheckMeleeAttack()

	local owner = self:GetOwner()
	local traces = owner:CompensatedZombieMeleeTrace(26, 12, owner:WorldSpaceCenter(), dir)
	local hit = false
	for _, trace in ipairs(traces) do
		if not self:IsMoaning() then continue end
		if not trace.Hit then continue end
		if trace.Entity.NextKnockdown and CurTime() < trace.Entity.NextKnockdown then continue end

		if trace.HitWorld then
			if trace.HitNormal.z < 0.8 then
				hit = true
			end
		else
			local ent = trace.Entity
			if ent and ent:IsValid() and not ent:IsProjectile() then
				hit = true
				--ent:TakeSpecialDamage(15, DMG_GENERIC, owner, self)
				if ent:IsPlayer() then
					ent:ThrowFromPositionSetZ(trace.StartPos, 90 + owner:GetVelocity():Length() * 2)
					if CurTime() >= (ent.NextKnockdown or 0) then
						ent:KnockDown()
						ent:EmitSound("player/pl_fallpain"..(math.random(2) == 1 and 3 or 1)..".wav")
						ent.NextKnockdown = CurTime() + 5
					end
				end
			end
		end
	end
end

function SWEP:Move(mv)
end

function SWEP:ApplyMeleeDamage(ent, trace, damage)
	self.BaseClass.ApplyMeleeDamage(self, ent, trace, damage)
end

function SWEP:StartSwinging()
	if not IsFirstTimePredicted() then return end

	local owner = self:GetOwner()
	local armdelay = owner:GetMeleeSpeedMul()

	self.MeleeAnimationMul = 1 / armdelay
	if self.MeleeAnimationDelay then
		self.NextAttackAnim = CurTime() + self.MeleeAnimationDelay * armdelay
	else
		self:SendAttackAnim()
	end

	self:DoSwingEvent()

	self:PlayAttackSound()

	--self:StopMoaning()

	if self.FrozenWhileSwinging then
		self:GetOwner():SetSpeed(1)
	end

	if self.MeleeDelay > 0 then
		self:SetSwingEndTime(CurTime() + self.MeleeDelay * armdelay)

		local trace = owner:CompensatedMeleeTrace(self.MeleeReach, self.MeleeSize)
		if trace.HitNonWorld and not trace.Entity:IsPlayer() then
			trace.IsPreHit = true
			self.PreHit = trace
		end

		self.IdleAnimation = CurTime() + (self:SequenceDuration() + (self.MeleeAnimationDelay or 0)) * armdelay
	else
		self:Swung()
	end
end

function SWEP:Initialize()
	self.BaseClass.Initialize(self)
end

function SWEP:OnRemove()
	self.BaseClass.OnRemove(self)
end

function SWEP:PrimaryAttack()
	--if not self:GetOwner():OnGround() then return end
	if self:GetNextSecondaryFire() > CurTime() then return end

	self.BaseClass.PrimaryAttack(self)

	if self:IsSwinging() then
		self:SetAttackAnimTime(CurTime() + self.Primary.Delay)
	end
end

function SWEP:ApplyMeleeDamage(hitent, tr, damage)
	self.BaseClass.ApplyMeleeDamage(self, hitent, tr, damage)
	--print(hitent)
	--print(hitent:IsPlayer())
	if not hitent:IsPlayer() then
		if hitent:GetClass() == "prop_door_rotating" then
			hitent.Heal = 0
		end
	end
end

function SWEP:StopMoaning()
	if not self:IsMoaning() then return end
	self:SetMoaning(false)

	--self:StopMoaningSound()
	self:GetOwner():ResetSpeed()
end

function SWEP:StartMoaning()
	if self:IsMoaning() or IsValid(self:GetOwner().Revive) or IsValid(self:GetOwner().FeignDeath) then return end
	self:SetMoaning(true)

	--self:SetMoanHealth(self:GetOwner():Health())
	self:GetOwner():SetWalkSpeed( self:GetOwner():GetZombieClassTable().RunSpeed )

	--self:StartMoaningSound()
end

function SWEP:IsMoaning()
	return self:GetMoaning() or false
end

function SWEP:PlayAlertSound()
	self.Owner:EmitSound("tank/voice/yell/tank_yell_0"..math.random(1, 9)..".wav", 77, 45)
end

function SWEP:PlayIdleSound()
	self.Owner:EmitSound("tank/voice/idle/tank_voice_0"..math.random(1, 9)..".wav", 77, 60)
end

function SWEP:PlayAttackSound()
	self.Owner:EmitSound("tank/voice/attack/tank_attack_0"..math.random(1, 9)..".wav")
end

function SWEP:PlayHitSound()
	self:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav", 77, math.random(60, 70))
end

function SWEP:PlayMissSound()
	self.Owner:EmitSound("npc/zombie/claw_miss"..math.random(2)..".wav", 77, math.random(60, 70))
end

function SWEP:IsInAttackAnim()
	return self:GetAttackAnimTime() > 0 and CurTime() < self:GetAttackAnimTime()
end

function SWEP:IsThrowingRockStart()
	return self:GetThrowingRockStart() > 0 and CurTime() < self:GetThrowingRockStart()
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Bool", 5, "IsThrowing" )
	self:NetworkVar( "Float", 5, "ThrowingRockStart" )
end
