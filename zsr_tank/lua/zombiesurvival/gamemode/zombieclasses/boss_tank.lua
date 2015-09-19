--Tank Class by Mka0207.
--Tank Model by MrPutisher.
--Model Link : http://steamcommunity.com/sharedfiles/filedetails/?id=299531234

util.PrecacheModel("models/enhanced_infected/hulk_2.mdl")

CLASS.Name = "Tank"
CLASS.TranslationName = "class_boss_tank"
CLASS.Description = "description_tank"
CLASS.Help = "controls_tank"

CLASS.Wave = 0
CLASS.Threshold = 0
CLASS.Unlocked = true
CLASS.Hidden = true
CLASS.Boss = true

CLASS.NoFallDamage = true
CLASS.NoFallSlowdown = true

CLASS.Health = 3500
CLASS.Speed = 180
CLASS.JumpPower = 250

CLASS.Points = 50

CLASS.CanTaunt = false

CLASS.FearPerInstance = 100

CLASS.SWEP = "weapon_zs_tank"

CLASS.Model = Model("models/enhanced_infected/hulk_2.mdl")

CLASS.DeathSounds = {"tank/voice/die/tank_death_0"..math.random(1, 7)..".wav"}

CLASS.PainSounds = {"tank/voice/pain/tank_pain_0"..math.random(1, 9)..".wav"}

CLASS.VoicePitch = 1

--Causes Tank Mouth Glitch
CLASS.ModelScale = 1

CLASS.CanFeignDeath = false

CLASS.SetSkin = true

CLASS.Skin = 0

--CLASS.Mass = 500
CLASS.ViewOffset = DEFAULT_VIEW_OFFSET * 1.6
CLASS.ViewOffsetDucked = DEFAULT_VIEW_OFFSET_DUCKED * CLASS.ModelScale
CLASS.Hull = {Vector(-16, -16, 0) * CLASS.ModelScale, Vector(16, 16, 64) * CLASS.ModelScale}
CLASS.HullDuck = {Vector(-16, -16, 0) * CLASS.ModelScale, Vector(16, 16, 32) * CLASS.ModelScale}

CLASS.Hull[1].x = -16
CLASS.Hull[2].x = 16
CLASS.Hull[1].y = -16
CLASS.Hull[2].y = 16
CLASS.HullDuck[1].x = -16
CLASS.HullDuck[2].x = 16
CLASS.HullDuck[1].y = -16
CLASS.HullDuck[2].y = 16

local mathrandom = math.random

local StepSounds = {
	"footsteps/tank/walk/tank_walk01.wav",
	"footsteps/tank/walk/tank_walk02.wav",
	"footsteps/tank/walk/tank_walk03.wav",
	"footsteps/tank/walk/tank_walk04.wav",
	"footsteps/tank/walk/tank_walk05.wav",
	"footsteps/tank/walk/tank_walk06.wav"
}

function CLASS:PlayerFootstep(pl, vFootPos, iFoot, strSoundName, fVolume, pFilter)

	if mathrandom() > 0.30 then
		pl:EmitSound(StepSounds[mathrandom(#StepSounds)], 70)
	end
	
	if EyePos():Distance(vFootPos) <= 300 then
		util.ScreenShake(vFootPos, 5, 5, 1, 300)
	end

	return true
end

function CLASS:Move(pl, mv)
	if mv:GetForwardSpeed() < 0 then
		mv:SetForwardSpeed( 0 )
	end
	
	mv:SetSideSpeed( 0 )
	
	local wep = pl:GetActiveWeapon()
	
	if wep:IsValid() and wep.IsInAttackAnim then
		if wep:IsInAttackAnim() then
			mv:SetForwardSpeed( 0 )
		end
	end
end


function CLASS:CalcMainActivity(pl, velocity)

	local wep = pl:GetActiveWeapon()
	
	if not wep:IsValid() then return end
	
	if wep.IsInAttackAnim then
		if wep:IsInAttackAnim() then
			if not pl:Crouching() then
				pl.CalcSeqOverride = pl:LookupSequence("Attack_Moving")
			else	
				pl.CalcSeqOverride = pl:LookupSequence("Attack_Incap")
			end
			return true
		end
	end
	
	if wep.IsMoaning then
		if wep:IsMoaning() then
			if velocity:Length2D() > 0.5 then
				if pl:OnGround() then
					pl.CalcSeqOverride = pl:LookupSequence("Run_1")
				else
					pl.CalcIdeal = ACT_JUMP
				end	
			else	
				pl.CalcSeqOverride = pl:LookupSequence("Idle_Full")
			end	
			return true
		end	
	end

	if pl:OnGround() then
		if velocity:Length2D() > 0.5 then
			if pl:Crouching() then
				pl.CalcIdeal = ACT_RUN_CROUCH
			else
				pl.CalcIdeal = ACT_WALK
			end	
		else
			pl.CalcIdeal = ACT_IDLE
		end
	elseif pl:WaterLevel() >= 1 then
		pl.CalcIdeal = ACT_WALK
	else
		pl.CalcIdeal = ACT_JUMP
	end
	
	return true
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)

	local wep = pl:GetActiveWeapon()
	if wep:IsValid() and wep.IsInAttackAnim then
		if wep:IsInAttackAnim() then
		
			if not pl:Crouching() then
				pl:SetPlaybackRate(0)
				pl:SetCycle((1 - (wep:GetAttackAnimTime() - CurTime()) / 1.5))
			else
				pl:SetCycle((1 - (wep:GetAttackAnimTime() - CurTime()) / 2))
			end

			return true
		end
	elseif wep:IsValid() and wep.IsMoaning and wep:IsMoaning() then
		pl:SetPlaybackRate(1)
	end
	
	local seq = pl:GetSequence()
	
	--print( seq )

	local len2d = velocity:Length2D()

	if len2d > 0.5 then
		pl:SetPlaybackRate(math.min(len2d / maxseqgroundspeed * 0.5, 1))
	else
		pl:SetPlaybackRate(1)
	end
	
	if !pl:IsOnGround() || pl:WaterLevel() >= 3 then
	
		pl:SetPlaybackRate(1)
	
		if pl:GetCycle() >= 1 then
			pl:SetCycle(pl:GetCycle() - 1)
		end

		return true
	end
	
	return true
end

function CLASS:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		return ACT_INVALID
	end
end

if SERVER then

	function CLASS:OnSpawned(pl)
	
		pl:CreateAmbience("tankambience")
		
	end
	
	function CLASS:OnKilled(pl)
	
		pl:CreateRagdoll()
		
	return true
		
	end

end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/tank_zsr_v1"