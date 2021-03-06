--[[ Author: Hewdraw, Noobsauce ]]

CreateEmptyTalents("crystal_maiden")

---------------------------------
-- 		   Arcane Dynamo       --
---------------------------------

imba_crystal_maiden_arcane_dynamo = class({})
LinkLuaModifier("modifier_imba_arcane_dynamo", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)

function imba_crystal_maiden_arcane_dynamo:GetIntrinsicModifierName() return "modifier_imba_arcane_dynamo" end
function imba_crystal_maiden_arcane_dynamo:IsInnateAbility() return true end

function imba_crystal_maiden_arcane_dynamo:GetAbilityTextureName()
   return "custom/crystal_maiden_arcane_dynamo"
end

---------------------------------
-- Arcane Dynamo Modifier      --
---------------------------------
modifier_imba_arcane_dynamo = class({})

function modifier_imba_arcane_dynamo:IsHidden() return false end
function modifier_imba_arcane_dynamo:IsDebuff() return false end
function modifier_imba_arcane_dynamo:IsPurgable() return false end

function modifier_imba_arcane_dynamo:OnCreated()
	-- Ability properties
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	-- Ability specials	
	self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")

	-- Start thinking
	self:StartIntervalThink(0.2)
end

function modifier_imba_arcane_dynamo:OnIntervalThink()
	if IsServer() then
		-- If the caster is broken, reset the stacks
		if self.caster:PassivesDisabled() then
			self:SetStackCount(0)
			return nil
		end

		local mana_percentage = self.caster:GetMana() / self.caster:GetMaxMana()
		local stacks = math.ceil(mana_percentage * self.max_stacks) 

		-- #4 Talent: Doubles Arcane Dynamo's effects
		stacks = stacks * math.max(1, (self.caster:FindTalentValue("special_bonus_imba_crystal_maiden_4")))

		self:SetStackCount(stacks)
	end
end

function modifier_imba_arcane_dynamo:DeclareFunctions()
	local decFuncs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
					  MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE}
 	
 	return decFuncs
end

function modifier_imba_arcane_dynamo:GetModifierMoveSpeedBonus_Percentage()
   -- Does nothing if hero has break
	if self.caster:PassivesDisabled() then
		return nil
	end

	-- Does nothing if hero is illusion
	if self.caster:IsIllusion() then
		return nil
	end

	return self:GetStackCount()
end

function modifier_imba_arcane_dynamo:GetModifierSpellAmplify_Percentage()
	-- Does nothing if hero has break
	if self.caster:PassivesDisabled() then
		return nil
	end
	-- Does nothing if hero is illusion
	if self.caster:IsIllusion() then
		return nil
	end
	
	return self:GetStackCount()
end

---------------------------------
-- 		   Crystal Nova        --
---------------------------------
imba_crystal_maiden_crystal_nova = class({})
LinkLuaModifier("modifier_imba_crystal_nova_slow", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_crystal_nova_snowfield_ally_aura", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_crystal_nova_snowfield_enemy_aura", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_crystal_nova_snowfield_debuff", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_crystal_nova_snowfield_buff", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)

function imba_crystal_maiden_crystal_nova:GetAbilityTextureName()
   return "crystal_maiden_crystal_nova"
end

function imba_crystal_maiden_crystal_nova:GetAOERadius() 
	return self:GetSpecialValueFor("nova_radius") + self:GetCaster():FindTalentValue("special_bonus_imba_crystal_maiden_3")
end	


function imba_crystal_maiden_crystal_nova:OnSpellStart()	
	-- Ability properties
	local caster = self:GetCaster()
	local ability = self
	local target_point = self:GetCursorPosition()
	local particle_nova = "particles/units/heroes/hero_crystalmaiden/maiden_crystal_nova.vpcf"
	local sound_nova = "soundevents/game_sounds_heroes/game_sounds_crystalmaiden.vsndevts"	
	local modifier_nova_debuff = "modifier_imba_crystal_nova_slow"
	local modifier_thinker_ally = "modifier_imba_crystal_nova_snowfield_ally_aura"	
	local modifier_thinker_enemy = "modifier_imba_crystal_nova_snowfield_enemy_aura"

	-- Ability specials
	local nova_radius = self:GetSpecialValueFor("nova_radius")	
	local nova_slow_duration = self:GetSpecialValueFor("nova_slow_duration")
	local nova_damage = self:GetSpecialValueFor("nova_damage")	
	local snowfield_duration = self:GetSpecialValueFor("snowfield_duration")
	local snowfield_vision_radius = self:GetSpecialValueFor("snowfield_vision_radius")

	-- Play Nova sound
	EmitSoundOnLocationWithCaster(target_point, "Hero_Crystal.CrystalNova", caster)

	-- Check for Nova AOE talent	
	nova_radius = nova_radius + caster:FindTalentValue("special_bonus_imba_crystal_maiden_3")			
	
	--Check for Nova damage talent	
	nova_damage = nova_damage + caster:FindTalentValue("special_bonus_imba_crystal_maiden_7")	
	
	-- Create modifier thinker
	local thinker = CreateModifierThinker(caster, ability, modifier_thinker_ally, {duration = snowfield_duration}, target_point, caster:GetTeamNumber(), false)
	thinker:AddNewModifier(caster, ability, modifier_thinker_enemy, {duration = snowfield_duration})
		
	-- Creates flying vision area
	self:CreateVisibilityNode(target_point, snowfield_vision_radius, snowfield_duration)

	--Emit Nova particle
	local nova_pfx = ParticleManager:CreateParticle(particle_nova, PATTACH_CUSTOMORIGIN, thinker)	
	ParticleManager:SetParticleControl(nova_pfx, 0, target_point)
	ParticleManager:SetParticleControl(nova_pfx, 1, Vector(nova_radius, nova_slow_duration, nova_radius))
	ParticleManager:SetParticleControl(nova_pfx, 2, target_point)
	ParticleManager:ReleaseParticleIndex(nova_pfx)	
	
	-- Find all enemies that would be in the nova radius
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
	                                  target_point,
	                                  nil,
	                                  nova_radius,
	                                  DOTA_UNIT_TARGET_TEAM_ENEMY,
	                                  DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	                                  DOTA_UNIT_TARGET_FLAG_NONE,
	                                  FIND_ANY_ORDER,
	                                  false)
								  
	-- Slow and damage all enemies caught in the radius
	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, self, "modifier_imba_crystal_nova_slow", {duration = nova_slow_duration} )
		ApplyDamage({attacker = caster, victim = enemy, ability = ability, damage = nova_damage, damage_type = DAMAGE_TYPE_MAGICAL})
	end
end

-- Crystal Nova main slow
modifier_imba_crystal_nova_slow = class({})

function modifier_imba_crystal_nova_slow:DeclareFunctions()	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT} end
function modifier_imba_crystal_nova_slow:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("nova_slow_percentage") * (-1) end
function modifier_imba_crystal_nova_slow:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("nova_slow_percentage") * (-1) end
function modifier_imba_crystal_nova_slow:GetEffectName() return "particles/generic_gameplay/generic_slowed_cold.vpcf" end
function modifier_imba_crystal_nova_slow:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_imba_crystal_nova_slow:IsHidden() return false end
function modifier_imba_crystal_nova_slow:IsDebuff() return true end
function modifier_imba_crystal_nova_slow:IsPurgable() return true end

-------------------------------------------
--            NOVA: SNOW FIELD
-------------------------------------------
modifier_imba_crystal_nova_snowfield_ally_aura = class({})

function modifier_imba_crystal_nova_snowfield_ally_aura:OnCreated()
	-- Ability properties
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.particle_snowfield_snow = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf"

	-- Ability specials
	self.snowfield_radius = self.ability:GetSpecialValueFor("snowfield_radius")

	local snowfield_pfx = ParticleManager:CreateParticle(self.particle_snowfield_snow, PATTACH_CUSTOMORIGIN, self.parent)	
	ParticleManager:SetParticleControl(snowfield_pfx, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl(snowfield_pfx, 1, Vector(self.snowfield_radius, 0, 0))	
	self:AddParticle(snowfield_pfx, false, false, -1, false, false)		
end

function modifier_imba_crystal_nova_snowfield_ally_aura:GetAuraRadius()
	return self.snowfield_radius
end

function modifier_imba_crystal_nova_snowfield_ally_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_imba_crystal_nova_snowfield_ally_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_imba_crystal_nova_snowfield_ally_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_imba_crystal_nova_snowfield_ally_aura:GetModifierAura()
	return "modifier_imba_crystal_nova_snowfield_buff"
end

function modifier_imba_crystal_nova_snowfield_ally_aura:IsAura()
	return true
end


modifier_imba_crystal_nova_snowfield_enemy_aura = class({})

function modifier_imba_crystal_nova_snowfield_enemy_aura:OnCreated()
	-- Ability properties
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	self.particle_snowfield_snow = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf"

	-- Ability specials
	self.snowfield_radius = self.ability:GetSpecialValueFor("snowfield_radius")	
	self.snowfield_damage_per_tick = self.ability:GetSpecialValueFor("snowfield_damage_per_tick")
	self.snowfield_damage_interval = self.ability:GetSpecialValueFor("snowfield_damage_interval")

	-- Calculate damage
	self.damage_per_tick = self.snowfield_damage_per_tick * self.snowfield_damage_interval
	
	if IsServer() then
		-- Start thinking
		self:StartIntervalThink(self.snowfield_damage_interval)
	end
end

function modifier_imba_crystal_nova_snowfield_enemy_aura:OnIntervalThink()
	if IsServer() then
		-- Find enemies, damage them
		local enemies = FindUnitsInRadius(self.caster:GetTeamNumber(),
								 		  self.parent:GetAbsOrigin(),
								 		  nil,
								 		  self.snowfield_radius,
								 		  DOTA_UNIT_TARGET_TEAM_ENEMY,
								 		  DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
								 		  DOTA_UNIT_TARGET_FLAG_NONE,
								 		  FIND_ANY_ORDER,
								 		  false)

		for _,enemy in pairs(enemies) do
			ApplyDamage({attacker = self.caster, victim = enemy, ability = self.ability, damage = self.damage_per_tick, damage_type = DAMAGE_TYPE_MAGICAL})
		end
	end
end

function modifier_imba_crystal_nova_snowfield_enemy_aura:GetAuraRadius()
	return self.snowfield_radius
end

function modifier_imba_crystal_nova_snowfield_enemy_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_imba_crystal_nova_snowfield_enemy_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_imba_crystal_nova_snowfield_enemy_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_imba_crystal_nova_snowfield_enemy_aura:GetModifierAura()
	return "modifier_imba_crystal_nova_snowfield_debuff"
end

function modifier_imba_crystal_nova_snowfield_enemy_aura:IsAura()
	return true
end



---------------------------
--    AURA MODIFIERS     --
---------------------------

-- AURA BUFF
modifier_imba_crystal_nova_snowfield_buff = class({})

function modifier_imba_crystal_nova_snowfield_buff:OnCreated()
	-- Ability properties
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	-- Ability specials
	self.snowfield_ally_buff = self.ability:GetSpecialValueFor("snowfield_ally_buff")	
end

function modifier_imba_crystal_nova_snowfield_buff:IsHidden() return false end
function modifier_imba_crystal_nova_snowfield_buff:IsPurgable() return false end
function modifier_imba_crystal_nova_snowfield_buff:IsDebuff() return false end

function modifier_imba_crystal_nova_snowfield_buff:DeclareFunctions()
	local decFuncs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return decFuncs
end

function modifier_imba_crystal_nova_snowfield_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.snowfield_ally_buff
end


-- AURA DEBUFF
modifier_imba_crystal_nova_snowfield_debuff = class({})

function modifier_imba_crystal_nova_snowfield_debuff:OnCreated()
	-- Ability properties
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	-- Ability specials
	self.snowfield_enemy_slow = self.ability:GetSpecialValueFor("snowfield_enemy_slow")	
end

function modifier_imba_crystal_nova_snowfield_debuff:IsHidden() return false end
function modifier_imba_crystal_nova_snowfield_debuff:IsPurgable() return false end
function modifier_imba_crystal_nova_snowfield_debuff:IsDebuff() return true end

function modifier_imba_crystal_nova_snowfield_debuff:DeclareFunctions()
	local decFuncs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return decFuncs
end

function modifier_imba_crystal_nova_snowfield_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.snowfield_enemy_slow * (-1)
end

function modifier_imba_crystal_nova_snowfield_debuff:GetEffectName() return "particles/generic_gameplay/generic_slowed_cold.vpcf" end
function modifier_imba_crystal_nova_snowfield_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end


---------------------------------
-- 		   Frost Bite          --
---------------------------------
LinkLuaModifier("modifier_imba_crystal_maiden_frostbite_passive_ready", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_crystal_maiden_frostbite_passive_recharging", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_crystal_maiden_frostbite_enemy", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_crystal_maiden_frostbite_ally", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)

imba_crystal_maiden_frostbite = class({})

function imba_crystal_maiden_frostbite:GetAbilityTextureName()
   return "crystal_maiden_frostbite"
end

function imba_crystal_maiden_frostbite:GetIntrinsicModifierName() return "modifier_imba_crystal_maiden_frostbite_passive_ready" end

function imba_crystal_maiden_frostbite:CastFilterResultTarget(target)
	if IsServer() then
		local caster = self:GetCaster()
		local casterID = caster:GetPlayerID()
		local targetID
		if target:IsHero() then			
			targetID = target:GetPlayerID()
		end
			
		-- Disable help
		if target ~= nil and targetID and not target:IsOpposingTeam(caster:GetTeamNumber()) and PlayerResource:IsDisableHelpSetForPlayerID(targetID,casterID) then
            return UF_FAIL_DISABLE_HELP
        end

		-- #2 Talent: Frostbite can be cast on allies, regenerating them.
		if target:GetTeamNumber() == caster:GetTeamNumber() and target:IsHero() and caster:HasTalent("special_bonus_imba_crystal_maiden_2") then
			return UF_SUCCESS
		end		

        local nResult = UnitFilter( target, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), self:GetCaster():GetTeamNumber() )
        return nResult
	end
end

function imba_crystal_maiden_frostbite:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		local position = self:GetCursorPosition()
		local duration = self:GetSpecialValueFor("duration")
		
		local duration_creep = self:GetSpecialValueFor("duration_creep")
		local duration_stun = self:GetSpecialValueFor("duration_stun")
		local damage_interval = self:GetSpecialValueFor("damage_interval")
		
		-- Check for duration increase talent. Does not work when casting on allies.
		if caster:HasTalent("special_bonus_imba_crystal_maiden_5") and caster:GetTeamNumber() ~= target:GetTeamNumber() then
			duration = duration + caster:FindTalentValue("special_bonus_imba_crystal_maiden_5")
		end
		
		-- If the target possesses a ready Linken's Sphere, do nothing else
		if target:GetTeamNumber() ~= caster:GetTeamNumber() then
			if target:TriggerSpellAbsorb(self) then return nil end
		end
		
		-- Applies root and damage to attacking unit according to its type, then triggers the cooldown accordingly
		if target:GetTeam() ~= caster:GetTeam() then
			if target:IsHero() or IsRoshan(target) or target:IsAncient() then
				target:AddNewModifier(caster, self, "modifier_stunned", {duration = duration_stun})				
				target:AddNewModifier(caster, self, "modifier_imba_crystal_maiden_frostbite_enemy", { duration = duration})
			else
				target:AddNewModifier(caster, self, "modifier_stunned", {duration = duration_stun})
				target:AddNewModifier(caster, self, "modifier_imba_crystal_maiden_frostbite_enemy", { duration = duration_creep})
			end
		elseif target:IsHero() then
			target:AddNewModifier(caster, self, "modifier_imba_crystal_maiden_frostbite_ally", { duration = duration})
		end
	end
end

-- Enemy Frost Bite Modifier
modifier_imba_crystal_maiden_frostbite_enemy = class({})

function modifier_imba_crystal_maiden_frostbite_enemy:CheckState() return {[MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true,} end

function modifier_imba_crystal_maiden_frostbite_enemy:OnCreated()
	if IsServer() then 
		--Define values
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.parent = self:GetParent()
		self.damage_interval = self.ability:GetSpecialValueFor("damage_interval")
		self.damage_per_tick = self.ability:GetSpecialValueFor("damage_per_tick")

		-- Immediately proc the first damage instance
		self:OnIntervalThink()
		
		--Play sound
		self:GetParent():EmitSound("Hero_Crystal.Frostbite")
		
		-- Get thinkin
		self:StartIntervalThink(self.damage_interval)
	end
end

function modifier_imba_crystal_maiden_frostbite_enemy:OnIntervalThink()
	if IsServer() then
		ApplyDamage({attacker = self.caster, victim = self.parent, ability = self.ability, damage = self.damage_per_tick, damage_type = DAMAGE_TYPE_MAGICAL})
	end
end

function modifier_imba_crystal_maiden_frostbite_enemy:GetEffectName() return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf" end
function modifier_imba_crystal_maiden_frostbite_enemy:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

-- Ally Frost Bite Modifier
modifier_imba_crystal_maiden_frostbite_ally = class({})

function modifier_imba_crystal_maiden_frostbite_ally:CheckState() return {[MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true,} end
function modifier_imba_crystal_maiden_frostbite_ally:OnCreated()
	if IsServer() then
		self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("damage_interval"))
		--Play sound
		self:GetParent():EmitSound("Hero_Crystal.Frostbite")
	end
end
function modifier_imba_crystal_maiden_frostbite_ally:DeclareFunctions()	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE} end

function modifier_imba_crystal_maiden_frostbite_ally:OnIntervalThink()
	if IsServer() then
		--Heal/Give Mana, then show values overhead
		self:GetParent():Heal(self:GetAbility():GetSpecialValueFor("heal_per_tick"),self:GetCaster())
		self:GetParent():GiveMana(self:GetAbility():GetSpecialValueFor("mana_per_tick"))
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetParent(), self:GetAbility():GetSpecialValueFor("heal_per_tick"), nil)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, self:GetParent(), self:GetAbility():GetSpecialValueFor("mana_per_tick"), nil)
	end
end
function modifier_imba_crystal_maiden_frostbite_ally:GetEffectName() return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf" end
function modifier_imba_crystal_maiden_frostbite_ally:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_imba_crystal_maiden_frostbite_ally:GetModifierIncomingDamage_Percentage()	return self:GetAbility():GetSpecialValueFor("ally_damage_reduction") end

modifier_imba_crystal_maiden_frostbite_passive_ready = class({})

function modifier_imba_crystal_maiden_frostbite_passive_ready:OnCreated()
	-- Ability properties
    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.modifier_recharge = "modifier_imba_crystal_maiden_frostbite_passive_recharging"

	-- If the caster has modifier recharge, commit sudoku
	   if self.caster:HasModifier(self.modifier_recharge) then self:Destroy() end	
end
function modifier_imba_crystal_maiden_frostbite_passive_ready:DeclareFunctions() return {MODIFIER_EVENT_ON_TAKEDAMAGE} end
function modifier_imba_crystal_maiden_frostbite_passive_ready:OnTakeDamage(keys)
	if IsServer() then
		-- If this is Rubick and Frostbite is no longer present, do nothing and kill the modifier
		if self.ability:IsStolen() then
			if not self.caster:FindAbilityByName("imba_crystal_maiden_frostbite") then
				self.caster:RemoveModifierByName("modifier_imba_crystal_maiden_frostbite_passive_ready")
				return nil
			end
		end
		
		local attacker = keys.attacker
		local unit = keys.unit
		
		local cooldown = self:GetAbility():GetSpecialValueFor("duration_passive_recharge")
		if self:GetParent():HasTalent("special_bonus_imba_crystal_maiden_6") then
			cooldown = cooldown - self:GetParent():FindTalentValue("special_bonus_imba_crystal_maiden_6")
			-- Do negative cooldowns break the game? IDK I'm not risking it
			if cooldown <= 0 then cooldown = .1 end
		end

		-- Only apply on damage against the caster, and when the attacking unit is an not magic immune enemy hero
		if unit == self.caster and attacker:GetTeam() ~= unit:GetTeam() and attacker:IsHero() and not attacker:IsMagicImmune() then
			-- If the caster is broken, do nothing
			if self.caster:PassivesDisabled() then
				return nil
			end

			--Apply Frost bite to enemy
			attacker:AddNewModifier(unit, self:GetAbility(), "modifier_imba_crystal_maiden_frostbite_enemy", { duration = self:GetAbility():GetLevelSpecialValueFor("duration", 0)})
			attacker:EmitSound("Hero_Crystal.Frostbite")
			unit:AddNewModifier(unit, self:GetAbility(), "modifier_imba_crystal_maiden_frostbite_passive_recharging", {duration = cooldown})
			self:Destroy()
		end
	end
end
function modifier_imba_crystal_maiden_frostbite_passive_ready:IsHidden() return false end
function modifier_imba_crystal_maiden_frostbite_passive_ready:IsDebuff() return false end
function modifier_imba_crystal_maiden_frostbite_passive_ready:IsPurgable() return false end

modifier_imba_crystal_maiden_frostbite_passive_recharging = class({})
function modifier_imba_crystal_maiden_frostbite_passive_recharging:OnCreated()
	-- Ability properties
	if IsServer() then
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.modifier_ready = "modifier_imba_crystal_maiden_frostbite_passive_ready"
	end
end
function modifier_imba_crystal_maiden_frostbite_passive_recharging:IsHidden() return false end
function modifier_imba_crystal_maiden_frostbite_passive_recharging:IsDebuff() return false end
function modifier_imba_crystal_maiden_frostbite_passive_recharging:IsPurgable() return false end
function modifier_imba_crystal_maiden_frostbite_passive_recharging:GetTexture() return "custom/crystal_maiden_frostbite_cooldown" end
function modifier_imba_crystal_maiden_frostbite_passive_recharging:OnDestroy()
    if IsServer() then
		self.caster:AddNewModifier(self.caster, self.ability, self.modifier_ready, {})
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------
-- Arcane/Brilliance/"Hey Gabe don't we call it Arcane Aura now why it is still labelled Brilliance Aura I mean its not a huge deal but cmon" Aura  --
------------------------------------------------------------------------------------------------------------------------------------------------------
imba_crystal_maiden_brilliance_aura = class({})

function imba_crystal_maiden_brilliance_aura:GetAbilityTextureName()
   return "crystal_maiden_brilliance_aura"
end

function imba_crystal_maiden_brilliance_aura:GetIntrinsicModifierName() return "modifier_imba_crystal_maiden_brilliance_aura_emitter" end

LinkLuaModifier("modifier_imba_crystal_maiden_brilliance_aura_emitter", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_crystal_maiden_brilliance_aura", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)

-- Brilcane Aura Emitter
modifier_imba_crystal_maiden_brilliance_aura_emitter = class({})

function modifier_imba_crystal_maiden_brilliance_aura_emitter:GetAuraRadius() return 25000 end -- global
function modifier_imba_crystal_maiden_brilliance_aura_emitter:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_imba_crystal_maiden_brilliance_aura_emitter:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_imba_crystal_maiden_brilliance_aura_emitter:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_imba_crystal_maiden_brilliance_aura_emitter:GetModifierAura() return "modifier_imba_crystal_maiden_brilliance_aura" end

function modifier_imba_crystal_maiden_brilliance_aura_emitter:IsAura()
	if self:GetCaster():PassivesDisabled() then
		return false
	end

	if self:GetCaster():IsIllusion() then
		return false
	end

	return true 
end

function modifier_imba_crystal_maiden_brilliance_aura_emitter:IsHidden() return true end
function modifier_imba_crystal_maiden_brilliance_aura_emitter:IsDebuff() return false end
function modifier_imba_crystal_maiden_brilliance_aura_emitter:IsPurgable() return false end

-- Arcilliance Aura
modifier_imba_crystal_maiden_brilliance_aura = class({})

function modifier_imba_crystal_maiden_brilliance_aura:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_imba_crystal_maiden_brilliance_aura:OnCreated()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()

	self.bonus_self = self.ability:GetSpecialValueFor("bonus_self")
	self.spellpower_threshold_pct = self.ability:GetSpecialValueFor("spellpower_threshold_pct")
end

function modifier_imba_crystal_maiden_brilliance_aura:OnRefresh()
	self:OnCreated()
end

function modifier_imba_crystal_maiden_brilliance_aura:DeclareFunctions()
	local funcs = {
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
		}
		return funcs
end

function modifier_imba_crystal_maiden_brilliance_aura:GetModifierConstantManaRegen()
	if self.parent == self.caster then
		return self:GetAbility():GetSpecialValueFor("mana_regen")* self.bonus_self
	else
		return self:GetAbility():GetSpecialValueFor("mana_regen")
	end
end
	
function modifier_imba_crystal_maiden_brilliance_aura:GetModifierBonusStats_Intellect() 
	if self.parent == self.caster then
		return self:GetAbility():GetSpecialValueFor("bonus_int")* self.bonus_self 
	else 
		return self:GetAbility():GetSpecialValueFor("bonus_int")
	end
end

function modifier_imba_crystal_maiden_brilliance_aura:GetModifierSpellAmplify_Percentage()
	-- Only apply if the parent has more than the spellpower threshold
	if self.parent and self.parent:GetManaPercent() > self.spellpower_threshold_pct then

		if self.parent == self.caster then
			return self:GetAbility():GetSpecialValueFor("bonus_spellpower") * self.bonus_self 
		else
			return self:GetAbility():GetSpecialValueFor("bonus_spellpower")
		end
	else

		return 0
	end
end

function modifier_imba_crystal_maiden_brilliance_aura:IsHidden() return false end
function modifier_imba_crystal_maiden_brilliance_aura:IsDebuff() return false end
function modifier_imba_crystal_maiden_brilliance_aura:IsPurgable() return false end

---------------------------------
-- 		   Freezing Field      --
---------------------------------
LinkLuaModifier("modifier_imba_crystal_maiden_freezing_field_aura", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_crystal_maiden_freezing_field_slow", "hero/hero_crystal_maiden.lua", LUA_MODIFIER_MOTION_NONE)

imba_crystal_maiden_freezing_field = class({})

function imba_crystal_maiden_freezing_field:GetAbilityTextureName()
   return "crystal_maiden_freezing_field"
end

--If caster has scepter, allow for ability to be cast at a point
function imba_crystal_maiden_freezing_field:GetBehavior()
	if self:GetCaster():HasScepter() then 
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
	else
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
	end
end

function imba_crystal_maiden_freezing_field:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function imba_crystal_maiden_freezing_field:OnSpellStart()  
	if IsServer() then 
		-- Ability properties
		local duration = self:GetSpecialValueFor("duration")
		local stun_duration = self:GetSpecialValueFor("stun_duration")	 
		local frostbite_duration = self:GetSpecialValueFor("frostbite_duration")	
		self.radius = self:GetSpecialValueFor("radius")
		self.caster = self:GetCaster()
		self.frametime = 0
		self.explosion_radius = self:GetSpecialValueFor("explosion_radius")	
		
		-- Quadrants 1: NW, 2: NE, 3: SE, 4: SW 
		self.quadrant= 1
		
		self.freezing_field_center = self.caster:GetAbsOrigin()
		
		if self.caster:HasScepter() then
			self.freezing_field_center = self:GetCursorPosition()
		end
		
		self.explosion_interval = self:GetSpecialValueFor("explosion_interval")	

		-- Check for talent
		if self.caster:HasTalent("special_bonus_imba_crystal_maiden_8") then
			self.explosion_interval = self.explosion_interval * self.caster:FindTalentValue("special_bonus_imba_crystal_maiden_8")			
		end
		
		-- Plays the channeling animation
		StartAnimation(self.caster, {activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.7})
		
		-- Find all enemies that would be in the freezing field
		local enemies = FindUnitsInRadius(self.caster:GetTeamNumber(),
										  self.freezing_field_center,
										  nil,
										  self.radius,
										  DOTA_UNIT_TARGET_TEAM_ENEMY,
										  DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
										  DOTA_UNIT_TARGET_FLAG_NONE,
										  FIND_ANY_ORDER,
										  false)

		-- Apply a reduced time frostbite to the enemies
		for _,enemy in pairs(enemies) do
			enemy:AddNewModifier(enemy, self, "modifier_imba_crystal_maiden_frostbite_enemy", {duration = frostbite_duration} )
		end
	
		--Slow aura
		self.freezing_field_aura = CreateModifierThinker(self.caster, self, "modifier_imba_crystal_maiden_freezing_field_aura", {duration = duration}, self.freezing_field_center, self.caster:GetTeamNumber(), false)	
		self.freezing_field_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf", PATTACH_CUSTOMORIGIN, self.freezing_field_aura)
		
		ParticleManager:SetParticleControl(self.freezing_field_particle, 0, self.freezing_field_center)
		ParticleManager:SetParticleControl(self.freezing_field_particle, 1, Vector (1000, 0, 0))
		ParticleManager:SetParticleControl(self.freezing_field_particle, 5, Vector (1000, 0, 0))
		
		-- Let it go?
		if USE_MEME_SOUNDS and RollPercentage(10) then
			--LET IT GO
			EmitSoundOnLocationWithCaster(self.freezing_field_center , "Hero_Crystal.CrystalNova", self.caster)
			self:EmitSound("Imba.CrystalMaidenLetItGo0"..RandomInt(1, 3))
			--I AM ONE WITH THE WIND AND SKYYY
		else
			self:EmitSound("hero_Crystal.freezingField.wind")
		end
	end
end

function imba_crystal_maiden_freezing_field:OnChannelThink()
	self.frametime = self.frametime + FrameTime()
	if self.frametime >= self.explosion_interval then
		self.frametime = 0
		
		-- Get random point
		local castDistance = RandomInt( self:GetSpecialValueFor("explosion_min_dist"), self:GetSpecialValueFor("explosion_max_dist") )
		local angle = RandomInt( 0, 90 )
		local dy = castDistance * math.sin( angle )
		local dx = castDistance * math.cos( angle )
		local attackPoint = Vector( 0, 0, 0 )
		local particle_name =  "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
		local target_loc = self.freezing_field_center
		
		if self.quadrant == 1 then			-- NW
			attackPoint = Vector( target_loc.x - dx, target_loc.y + dy, target_loc.z )
		elseif self.quadrant == 2 then		-- NE
			attackPoint = Vector( target_loc.x + dx, target_loc.y + dy, target_loc.z )
		elseif self.quadrant == 3 then		-- SE
			attackPoint = Vector( target_loc.x + dx, target_loc.y - dy, target_loc.z )
		else								-- SW
			attackPoint = Vector( target_loc.x - dx, target_loc.y - dy, target_loc.z )
		end
		
		--Increment quadrant for next think
		self.quadrant = 4 % (self.quadrant + 1)			

		-- Loop through units in the shard's AoE
		local units = FindUnitsInRadius(self.caster:GetTeam(), attackPoint, nil, self.explosion_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)

		for _,v in pairs( units ) do
			ApplyDamage({victim =  v, attacker = self.caster, damage = self:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self})
		end
		
		-- Create particle/sound dummy unit
		local explosion_dummy = CreateUnitByName("npc_dummy_unit", attackPoint, false, nil, nil, self.caster:GetTeamNumber())
		
		-- Fire effect
		local fxIndex = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(fxIndex, 0, explosion_dummy:GetAbsOrigin())
		ParticleManager:SetParticleControl(fxIndex, 1, explosion_dummy:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(fxIndex)

		-- Fire sound at the center position
		explosion_dummy:EmitSound("hero_Crystal.freezingField.explosion")

		-- Destroy dummy
		explosion_dummy:Destroy()
	end
	
end

function imba_crystal_maiden_freezing_field:OnChannelFinish(bInterrupted)
	if IsServer() then
		--SHUT UP ALREADY
		self:StopSound("hero_Crystal.freezingField.wind")
		self:StopSound("Imba.CrystalMaidenLetItGo01")
		self:StopSound("Imba.CrystalMaidenLetItGo02")
		self:StopSound("Imba.CrystalMaidenLetItGo03")
		
		-- Stop animation
		EndAnimation(self.caster)
		
		--Kill Particles
		ParticleManager:DestroyParticle(self.freezing_field_particle, true)
		ParticleManager:ReleaseParticleIndex(self.freezing_field_particle)
		
		--Reset positions
		self.freezing_field_center = nil
	end
end

--Freezing field aura emitter
modifier_imba_crystal_maiden_freezing_field_aura = class({})

function modifier_imba_crystal_maiden_freezing_field_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_imba_crystal_maiden_freezing_field_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_imba_crystal_maiden_freezing_field_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_imba_crystal_maiden_freezing_field_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_imba_crystal_maiden_freezing_field_aura:GetModifierAura() return "modifier_imba_crystal_maiden_freezing_field_slow" end
function modifier_imba_crystal_maiden_freezing_field_aura:IsAura() return true end
function modifier_imba_crystal_maiden_freezing_field_aura:IsHidden() return false end
function modifier_imba_crystal_maiden_freezing_field_aura:IsDebuff() return true end
function modifier_imba_crystal_maiden_freezing_field_aura:IsPurgable() return true end

--Freezing field slow
modifier_imba_crystal_maiden_freezing_field_slow = class({})

function modifier_imba_crystal_maiden_freezing_field_slow:DeclareFunctions() return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT} end
function modifier_imba_crystal_maiden_freezing_field_slow:GetModifierMoveSpeedBonus_Percentage() return (self:GetAbility():GetSpecialValueFor("slow") + self:GetCaster():FindTalentValue("special_bonus_imba_crystal_maiden_1")) * (-1) end
function modifier_imba_crystal_maiden_freezing_field_slow:GetModifierAttackSpeedBonus_Constant() return (self:GetAbility():GetSpecialValueFor("slow") + self:GetCaster():FindTalentValue("special_bonus_imba_crystal_maiden_1")) * (-1) end
function modifier_imba_crystal_maiden_freezing_field_slow:IsHidden() return false end
function modifier_imba_crystal_maiden_freezing_field_slow:IsDebuff() return true end
function modifier_imba_crystal_maiden_freezing_field_slow:IsPurgable() return false end