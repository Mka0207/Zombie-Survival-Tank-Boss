--Zombie Survival Tank Boss Class by Mka0207 : http://steamcommunity.com/id/mka0207/
--Tank Model by MrPutisher : http://steamcommunity.com/profiles/76561198028565839

util.PrecacheModel("models/enhanced_infected/zombie_hulk_v2.mdl")

CLASS.Name = "Tank"
CLASS.TranslationName = "class_boss_tank"
CLASS.Description = "description_tank"
CLASS.Help = "controls_tank"

CLASS.SWEP = "weapon_zs_tank"
CLASS.Model = Model( "models/enhanced_infected/zombie_hulk_v2.mdl" )
CLASS.DeathSounds = { "tank/voice/die/tank_death_0"..math.random(1, 7)..".wav" }
CLASS.PainSounds = { "tank/voice/pain/tank_pain_0"..math.random(1, 9)..".wav" }

CLASS.Wave = 0
CLASS.Threshold = 0
CLASS.KnockbackScale = 0

CLASS.Unlocked = true
CLASS.Hidden = true
CLASS.Boss = true
CLASS.NoFallDamage = true
CLASS.NoFallSlowdown = true
CLASS.NoGibs = true
CLASS.CanTaunt = false
CLASS.CanFeignDeath = false

CLASS.Health = 4000
CLASS.Speed = 160
CLASS.JumpPower = 275
CLASS.Points = 30
CLASS.FearPerInstance = 100
CLASS.VoicePitch = 1
CLASS.ModelScale = 1 --Please don't set this above 1.1, it causes the mouth bone to glitch.

CLASS.ViewOffset = DEFAULT_VIEW_OFFSET * 1.1
CLASS.ViewOffsetDucked = DEFAULT_VIEW_OFFSET_DUCKED * CLASS.ModelScale

CLASS.Hull = {Vector(-16, -16, 0) * CLASS.ModelScale, Vector(16, 16, 64) * CLASS.ModelScale}
CLASS.HullDuck = {Vector(-16, -16, 0) * CLASS.ModelScale, Vector(16, 16, 38) * CLASS.ModelScale}
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

	--Stop the Tank from being able to move backwards.
	if mv:GetForwardSpeed() < 0 then
		mv:SetForwardSpeed( 0 )
	end
	
	--Prevent the Tank from moving sideways as well.
	--I do this because the Tank's animations aren't 9 set.
	mv:SetSideSpeed( 0 )
	
	--As well as stopping the Tank when it crouch attacks, similar to L4D2.
	local wep = pl:GetActiveWeapon()
	if wep:IsValid() and wep.IsInAttackAnim then
		if wep:IsInAttackAnim() then
			if pl:Crouching() then
				mv:SetForwardSpeed( 0 )
			end	
		end
	end
end

--I spent a few hours testing out animations, this build I made worked the best for the Tank.
function CLASS:CalcMainActivity(pl, velocity)

	local wep = pl:GetActiveWeapon()
	
	if not wep:IsValid() then return end
	
	if wep.IsInAttackAnim then
		if wep:IsInAttackAnim() then
			if not pl:Crouching() then
				if velocity:Length2D() > 0.5 then
					pl.CalcSeqOverride = pl:LookupSequence("Hulk_Runmad")
				else
					pl.CalcSeqOverride = pl:LookupSequence("Attack_Moving")
				end	
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

	--print( "Debug! : Current Animation Sequence Number is "..pl:GetSequence() ) // I used this to figure out the numbers of each animation.

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
		
		--Neat little ambience that plays the Tank theme from L4D2.
		pl:CreateAmbience("tankambience")
		pl:SetBodygroup( 1, 0 )
		
	end
	
	function CLASS:OnKilled(pl)
	
		-- CLASS.NoGib doesn't work for some reason, so we do this.
		pl:CreateRagdoll()
		
		return true	
	end

end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/zs_tank_v2"