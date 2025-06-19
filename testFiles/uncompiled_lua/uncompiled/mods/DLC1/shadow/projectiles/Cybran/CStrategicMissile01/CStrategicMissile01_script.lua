-----------------------------------------------------------------------------
--  File     :  /projectiles/cybran/cstrategicmissile01/cstrategicmissile01_script.lua
--  Author(s):	Aaron Lundquist
--  Summary  :  SC2 Cybran Strategic Missile: CStrategicMissile01
--  Copyright � 2009 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------
local CEMPFluxWarheadProjectile = import('/lua/sim/Projectile.lua').Projectile
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

CStrategicMissile01 = Class(CEMPFluxWarheadProjectile) {

    FxSplashScale = 0.5,
    FxTrails = {},

    LaunchSound = 'Nuke_Launch',
    ExplodeSound = 'Nuke_Impact',
    AmbientSound = 'Nuke_Flight',

    InitialEffects = {
		'/effects/emitters/weapons/cybran/nuke01/launch/w_c_nuke01_l_01_lightsmoke_emit.bp',
		'/effects/emitters/weapons/cybran/nuke01/launch/w_c_nuke01_l_02_smokecloud_emit.bp',
		'/effects/emitters/weapons/cybran/nuke01/launch/w_c_nuke01_l_03_smokespire_emit.bp',
    },
    LaunchEffects = {
		'/effects/emitters/weapons/cybran/nuke01/launch/w_c_nuke01_l_04_presmoke_emit.bp',
		'/effects/emitters/weapons/cybran/nuke01/launch/w_c_nuke01_l_05_prefire_emit.bp',
    },
    ThrustEffects = {
		'/effects/emitters/weapons/cybran/nuke01/projectile/w_c_nuke01_p_01_fire_emit.bp',
		'/effects/emitters/weapons/cybran/nuke01/projectile/w_c_nuke01_p_02_glow_emit.bp',
		'/effects/emitters/weapons/cybran/nuke01/projectile/w_c_nuke01_p_03_ignitefire_emit.bp',
		'/effects/emitters/weapons/cybran/nuke01/projectile/w_c_nuke01_p_04_smoke_emit.bp',
		'/effects/emitters/weapons/cybran/nuke01/projectile/w_c_nuke01_p_05_ring_emit.bp',
    },
    
	BeamName = '/effects/emitters/ambient/units/default_beam_01_emit.bp',

    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE, TargetEntity) then
            -- Play the explosion sound
            local myBlueprint = self:GetBlueprint()
            if myBlueprint.Audio.Explosion then
                self:PlaySound(myBlueprint.Audio.Explosion)
            end
            
			nukeProjectile = self:CreateProjectile('/effects/Entities/UEFNukeEffectController01/UEFNukeEffectController01_proj.bp', 0, 0, 0, nil, nil, nil):SetCollision(false)
            local pos = self:GetPosition()
            pos[2] = pos[2] + 5
            Warp( nukeProjectile, pos)
            nukeProjectile:PassData(self.Data)

            local pos = self:GetPosition()
	        local spec = {
	            X = pos[1],
	            Z = pos[3],
	            Radius = 50,
	            LifeTime = 20,
	            Omni = false,
	            Vision = true,
	            Army = self:GetArmy(),
	        }
	        local vizEntity = VizMarker(spec)
        end
        CEMPFluxWarheadProjectile.OnImpact(self, TargetType, TargetEntity)
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if self.ProjectileDamaged then
            for k,v in self.ProjectileDamaged do
                v(self)
            end
        end
        CEMPFluxWarheadProjectile.OnDamage(self, instigator, amount, vector, damageType)
    end,

    OnCreate = function(self)
        CEMPFluxWarheadProjectile.OnCreate(self)
		CreateBeamEmitterOnEntity( self, -1, self:GetArmy(), self.BeamName )
        local launcher = self:GetLauncher()
        if launcher and not launcher:IsDead() then
            if launcher.EventCallbacks.ProjectileDamaged then
                self.ProjectileDamaged = {}
                for k,v in launcher.EventCallbacks.ProjectileDamaged do
                    table.insert( self.ProjectileDamaged, v )
                end
            end
            self.cachedLaunchPos = launcher:GetPosition()
        end
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.MovementTurnLevel = 1

		-- Cache target position, since this projectile does not track targets
		self.cachedTargetPos = self:GetCurrentTargetPosition()
		if not self.cachedTargetPos then
			LOG( 'CStrategicMissile01 created with no target' )
			self.cachedTargetPos = Vector(0,0,0)
		end

        self.moveThread = self:ForkThread( self.MovementThread )
    end,

    CreateEffects = function( self, EffectTable, army, scale)
        for k, v in EffectTable do
            self.Trash:Add(CreateAttachedEmitter(self, -1, army, v):ScaleEmitter(scale))
        end
    end,

    MovementThread = function(self)
        local army = self:GetArmy()
        local launcher = self:GetLauncher()
        self.CreateEffects( self, self.InitialEffects, army, 1 )
        self:TrackTarget(false)
        WaitSeconds(1)				-- Height
        self:SetCollision(true)
        self.CreateEffects( self, self.LaunchEffects, army, 1 )
        WaitSeconds(3)
        self.CreateEffects( self, self.ThrustEffects, army, 3 )
        WaitSeconds(2.5)
        self:TrackTarget(true) -- Turn ~90 degrees towards target
        self:SetDestroyOnWater(true)
        self:SetTurnRate(47.36)
        WaitSeconds(2) 					-- Now set turn rate to zero so nuke flies straight
        self:SetTurnRate(0)
        self:SetAcceleration(0.001)
        self.WaitTime = 0.5
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,
	
    RedirectedMovementThread = function(self)
        self:SetTurnRate(47.36)
        WaitSeconds(2) 					-- Now set turn rate to zero so nuke flies straight
        self:SetTurnRate(0)
        self:SetAcceleration(0.001)
        self.WaitTime = 0.5
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        -- Get the nuke as close to 90 deg as possible
        if dist > 150 then
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            self:SetTurnRate(0)
        elseif dist > 75 and dist <= 150 then
			-- Increase check intervals
            self.WaitTime = 0.3
        elseif dist > 32 and dist <= 75 then
			-- Further increase check intervals
            self.WaitTime = 0.1
        elseif dist < 32 then
			-- Turn the missile down
            self:SetTurnRate(50)
        end
    end,

    GetDistanceToTarget = function(self)
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], self.cachedTargetPos[1], self.cachedTargetPos[3])
        return dist
    end,
	
	UpdateCachedTarget = function(self)
		if self.moveThread then
			KillThread(self.moveThread)
		end
		self.cachedTargetPos = self:GetCurrentTargetPosition()
		self.moveThread = self:ForkThread( self.RedirectedMovementThread )
	end,
}
TypeClass = CStrategicMissile01