if not gamemode.Get("zombiesurvival") then return end

AddCSLuaFile()

SWEP.Base = "weapon_zs_zombie"

SWEP.MeleeReach = 50
SWEP.MeleeDamage = 40
SWEP.MeleeForceScale = 5
SWEP.MeleeSize = 2.8
SWEP.MeleeDamageType = DMG_SLASH
SWEP.Primary.Delay = 1.5
SWEP.Primary.Automatic = false
SWEP.Secondary.Delay = 5

AccessorFuncDT(SWEP, "AttackAnimTime", "Float", 3)

function SWEP:CheckMoaning()
	if self:IsMoaning() and self.Owner:Health() < self:GetMoanHealth() then
		self:SetNextSecondaryFire(CurTime() + 1)
		self:StopMoaning()
	end
end

function SWEP:Think()
	self:CheckMeleeAttack()
	--self:CheckMoaning()
end

function SWEP:ApplyMeleeDamage(ent, trace, damage)
	if ent:IsValid() and ent:IsPlayer() then
		local vel = ent:GetPos() - self.Owner:GetPos()
		vel.z = 0
		vel:Normalize()
		vel = vel * 400
		vel.z = 200

		ent:KnockDown()
		ent:SetGroundEntity(NULL)
		ent:SetVelocity(vel)
	end

	self.BaseClass.ApplyMeleeDamage(self, ent, trace, damage)
end

function SWEP:PrimaryAttack()
	if not self.Owner:OnGround() then return end

	self.BaseClass.PrimaryAttack(self)

	if self:IsSwinging() then
		self:SetAttackAnimTime(CurTime() + self.Primary.Delay)
	end
end

function SWEP:SecondaryAttack()
	self.BaseClass.SecondaryAttack(self)
end

function SWEP:StartSwinging()
	if self.MeleeAnimationDelay then
		self.NextAttackAnim = CurTime() + self.MeleeAnimationDelay
	else
		self:SendAttackAnim()
	end

	local owner = self.Owner
	owner:DoAttackEvent()

	if SERVER then
		self:PlayAttackSound()
	end
	--self:StopMoaning()

	if self.FrozenWhileSwinging then
		owner:SetSpeed(1)
	end

	if self.MeleeDelay > 0 then
		self:SetSwingEndTime(CurTime() + self.MeleeDelay)

		local trace = self.Owner:MeleeTrace(self.MeleeReach, self.MeleeSize, player.GetAll())
		if trace.HitNonWorld then
			trace.IsPreHit = true
			self.PreHit = trace
		end

		self.IdleAnimation = CurTime() + self:SequenceDuration()
	else
		self:Swung()
	end
end

function SWEP:StopMoaning()
	if not self:IsMoaning() then return end
	self:SetMoaning(false)
	self.Owner:ResetSpeed()
end

function SWEP:StartMoaning()
	--if not self.Owner.m_Boss_Moan then return end
	if self:IsMoaning() then return end
	self:SetMoaning(true)
	
	self.Owner:SetWalkSpeed( self.Owner:GetMaxSpeed() * 1.8 )

	self:SetMoanHealth(self.Owner:Health())
end

function SWEP:IsInAttackAnim()
	return self:GetAttackAnimTime() > 0 and CurTime() < self:GetAttackAnimTime()
end

function SWEP:OnRemove()
	if IsValid(self.Owner) then
		self:StopMoaning()
	end
end
SWEP.Holster = SWEP.OnRemove

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
	self.Owner:EmitSound("physics/body/body_medium_impact_hard"..math.random(6)..".wav", 77, math.random(60, 70))
end

function SWEP:PlayMissSound()
	self.Owner:EmitSound("npc/zombie/claw_miss"..math.random(2)..".wav", 77, math.random(60, 70))
	
end

function SWEP:SetMoaning(moaning)
	self:SetDTBool(0, moaning)
end

function SWEP:GetMoaning()
	return self:GetDTBool(0)
end
SWEP.IsMoaning = SWEP.GetMoaning

function SWEP:SetMoanHealth(health)
	self:SetDTInt(0, health)
end

function SWEP:GetMoanHealth()
	return self:GetDTInt(0)
end