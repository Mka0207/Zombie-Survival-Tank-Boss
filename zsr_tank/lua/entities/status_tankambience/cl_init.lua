include("shared.lua")

ENT.RenderGroup = RENDERGROUP_NONE

function ENT:Initialize()
	self:DrawShadow(false)
	
	self.AmbientSound = CreateSound(self, "zombiesurvival/tank_theme_loop.ogg")
	self.AmbientSound:PlayEx(1, 100)
end

function ENT:OnRemove()
	self.AmbientSound:Stop()
end

function ENT:Think()

end

function ENT:Draw()
end
