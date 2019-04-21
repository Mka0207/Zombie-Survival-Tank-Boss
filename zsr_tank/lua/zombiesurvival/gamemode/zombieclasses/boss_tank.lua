--Zombie Survival Tank Boss Class by Mka0207 : http://steamcommunity.com/id/mka0207/
--Tank Model by MrPutisher : http://steamcommunity.com/profiles/76561198028565839
--Version 2.0 - 2018

util.PrecacheModel("models/enhanced_infected/zombie_hulk_v2.mdl")

CLASS.Name = "Tank"
CLASS.TranslationName = "class_boss_tank"
CLASS.Description = "description_boss_tank"
CLASS.Help = "controls_boss_tank"

CLASS.SWEP = "weapon_zs_tank"
CLASS.Model = Model( "models/enhanced_infected/zombie_hulk_v2.mdl" )
CLASS.DeathSounds = { "tank/voice/die/tank_death_0"..math.random(1, 7)..".wav" }
CLASS.PainSounds = { "tank/voice/pain/tank_pain_0"..math.random(1, 9)..".wav" }

CLASS.Wave = 0
CLASS.Boss = true

CLASS.Threshold = 0
CLASS.KnockbackScale = 0

CLASS.NoFallDamage = true
CLASS.NoFallSlowdown = true
CLASS.NoGibs = true
CLASS.CanTaunt = false
CLASS.CanFeignDeath = false

CLASS.Health = 4000
CLASS.Speed = 140
CLASS.RunSpeed = 300
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
	"tank/footsteps/tank/walk/tank_walk01.wav",
	"tank/footsteps/tank/walk/tank_walk02.wav",
	"tank/footsteps/tank/walk/tank_walk03.wav",
	"tank/footsteps/tank/walk/tank_walk04.wav",
	"tank/footsteps/tank/walk/tank_walk05.wav",
	"tank/footsteps/tank/walk/tank_walk06.wav"
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
	--SWEP functions
	local wep = pl:GetActiveWeapon()
	if wep.Move and wep:Move(mv) then
		return true
	end

	--Stop the Tank from being able to move backwards.
	if mv:GetForwardSpeed() < 0 then
		mv:SetForwardSpeed( 0 )
	end

	--Prevent the Tank from moving sideways as well.
	--I do this because the Tank's animations aren't 9 set.
	mv:SetSideSpeed( 0 )

	--As well as stopping the Tank when it crouch attacks, similar to L4D2.
	local wep = pl:GetActiveWeapon()
	if wep:IsValid() then
		if wep.IsInAttackAnim and wep:IsInAttackAnim() then
			if pl:Crouching() then
				mv:SetForwardSpeed( 0 )
			end
		end
		if wep.GetIsThrowing and wep:GetIsThrowing() then
			if bit.band(mv:GetButtons(), IN_JUMP) ~= 0 then
				mv:SetButtons(mv:GetButtons() - IN_JUMP)
			end
			mv:SetForwardSpeed( 0 )
		end
	end
end

--I spent a few hours testing out animations, this build I made worked the best for the Tank.
function CLASS:CalcMainActivity(pl, velocity)

	local wep = pl:GetActiveWeapon()
	if wep and IsValid(wep) then
		if wep.IsInAttackAnim and wep:IsInAttackAnim() then
			if not pl:Crouching() then
				if velocity:Length2D() > 0.5 then
					return 1, pl:LookupSequence("Hulk_Runmad")
				else
					return 1, pl:LookupSequence("Attack_Moving")
				end
			else
				return 1, pl:LookupSequence("Attack_Incap")
			end
		end

		if wep.IsMoaning and wep:IsMoaning() then
			if velocity:Length2D() > 0.5 then
				if pl:OnGround() then
					return 1, pl:LookupSequence("Run_1")
				else
					return ACT_JUMP, -1
				end
			else
				if wep.IsThrowingRockStart and wep:IsThrowingRockStart() then
					return 1, pl:LookupSequence("Throw_02")
					--return ACT_TANK_OVERHEAD_THROW, -1
				else
					return 1, pl:LookupSequence("Idle_Full")
				end
			end
		end
	end

	if pl:OnGround() then
		if velocity:Length2D() > 0.5 then
			if pl:Crouching() then
				return ACT_RUN_CROUCH, -1
			else
				return ACT_WALK, -1
			end
		else
			if wep.IsThrowingRockStart and wep:IsThrowingRockStart() then
				return 1, pl:LookupSequence("Throw")
			else
				return 1, pl:LookupSequence("Idle_Full")
			end
		end
	elseif pl:WaterLevel() >= 1 then
		return ACT_WALK, -1
	else
		return ACT_JUMP, -1
	end

	return true
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	pl:FixModelAngles(velocity)
	--print( "Debug! : Current Animation Sequence Number is "..pl:GetSequence() ) // I used this to figure out the numbers of each animation.

	local len2d = velocity:Length2D()
	local wep = pl:GetActiveWeapon()

	if len2d > 0.5 then
		pl:SetPlaybackRate( math.min( len2d / maxseqgroundspeed * 0.5, 1 ) )
	else
		--pl:SetPlaybackRate(1)
		if wep and wep:IsValid() then
			if wep.IsThrowingRockStart and wep:IsThrowingRockStart() then
				if not pl.m_PrevFrameCycle then
					pl.m_PrevFrameCycle = true
					pl:SetCycle(0)
				end
				--pl:SetPlaybackRate(0)
				-- self:SetPlaybackRate( math.min( len2d / maxseqgroundspeed * 0.5, 1 ) )
				return true
			elseif pl.m_PrevFrameCycle then
				pl.m_PrevFrameCycle = nil
			end
		end
	end
	if wep:IsValid() then
		if wep.IsInAttackAnim and wep:IsInAttackAnim() then

			if not pl:Crouching() then
				pl:SetPlaybackRate(0)
				pl:SetCycle((1 - (wep:GetAttackAnimTime() - CurTime()) / 1.5))
			else
				pl:SetCycle((1 - (wep:GetAttackAnimTime() - CurTime()) / 2))
			end
		end
	end

	if !pl:IsOnGround() || pl:WaterLevel() >= 3 then

		pl:SetPlaybackRate(1)

		if pl:GetCycle() >= 1 then
			pl:SetCycle(pl:GetCycle() - 1)
		end
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
		--pl:CreateAmbience("tankambience")
		pl:SetBodygroup( 1, 0 )
	end

	function CLASS:OnKilled(pl)
		-- CLASS.NoGib doesn't work for some reason, so we do this.
		pl:SetBodygroup( 1, 0 )
		pl:CreateRagdoll()
		return true
	end

	function CLASS:ProcessDamage(pl, dmginfo)
		local attacker = dmginfo:GetAttacker()
		local dist = pl:GetPos():Distance(attacker:GetPos())
		local distdropoff = 256

		if dmginfo:IsBulletDamage() then
			if dist > distdropoff * 2 then
				dmginfo:ScaleDamage(0.5)
			elseif dist > distdropoff then
				dmginfo:ScaleDamage(0.75)
			else
				dmginfo:ScaleDamage(1)
			end
		end
	end

	--[[function CLASS:OnPlayerHitGround(player, inWater, onFloater, speed)
		local pos = player:GetPos() + Vector(0, 0, 2)

		player:LagCompensation(true)

		player:EmitSound("physics/concrete/concrete_break3.wav", 77, 70)

		util.ScreenShake(pos, 5, 5, 1, 300)

		local effectdata = EffectData()
			effectdata:SetOrigin(pos)
			effectdata:SetNormal(Vector(0, 0, 1))
		util.Effect("ThumperDust", effectdata, true, true)

		player:GodEnable()
			util.BlastDamageEx(player, player, pos, 112, 25, DMG_CLUB)
		player:GodDisable()

		player:LagCompensation(false)
	end]]
end

if CLIENT then
	CLASS.Icon = "zombiesurvival/killicons/zs_tank_v2"
	CLASS.Image = "class_icons/tank.png"
end
