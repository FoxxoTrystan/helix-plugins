PLUGIN.name = "ARC9 Compatibility"
PLUGIN.author = "FoxxoTrystan"
PLUGIN.description = "ARC9 Compatibility for the HELIX Gamemode."

if (ARC9) then
    --// CONFIG
    if (ix.plugin.Get("persistent_corpses")) then
        ix.config.Add("DropWeaponsOnDeath", false, "Drop Weapons on death.", nil, {
            category = PLUGIN.name
        })

        ix.config.Add("DropAttachementsOnDeath", false, "Drop Attachements on death.", nil, {
            category = PLUGIN.name
        })
    end

    --// CLIENT
    if(CLIENT) then
        GetConVar("arc9_hud_arc9"):SetInt(0)
        GetConVar("arc9_cross_enable"):SetInt(0)
    end
    
    --// HOOKS
    --// Attachements PostPlayerLoadout
    function PLUGIN:PostPlayerLoadout(client)
        client.ARC9_AttInv = {}

        for i,v in pairs(client:GetCharacter():GetInventory():GetItems()) do
            if v.category == "Attachements" then
                ARC9:PlayerGiveAtt(client, v.att)
                ARC9:PlayerSendAttInv(client)
            end
        end
    end

    --// ARC9RemoveGrenade
    GrenadeClass = {}
    hook.Add("EntityRemoved", "ARC9RemoveGrenade", function(entity)
        if (GrenadeClass[entity:GetClass()]) then
            local client = entity:GetOwner()
            if (IsValid(client) and client:IsPlayer() and client:GetCharacter()) then
                local ammoName = game.GetAmmoName(entity:GetPrimaryAmmoType())
                if (isstring(ammoName) and client:GetAmmoCount(ammoName) < 1
                and entity.ixItem and entity.ixItem.Unequip) then
                    entity.ixItem:Unequip(client, false, true)
                end
            end
        end
    end)
end

function PLUGIN:InitializedPlugins()
    if (!ARC9) then
        return print("// ARC9 Compatibility - Cant find ARC9 Addon! //")
    else
        if (SERVER) then
            ARC9.NoHUD = true
            GetConVar("arc9_free_atts"):SetInt(0)
            GetConVar("arc9_atts_lock"):SetInt(0)
        end
        print("// ARC9 Compatibility - Loading Weapons... //")
        for i,v in pairs(weapons.GetList()) do
            if weapons.IsBasedOn(v.ClassName, "arc9_base") then
                ALWAYS_RAISED[v.ClassName] = true
                local ITEM = ix.item.Register(v.ClassName, "base_weapons", false, nil, true)
                ITEM.name = v.PrintName
                ITEM.description = v.Description or nil
                ITEM.model = v.WorldModel
                ITEM.class = v.ClassName
                ITEM.width = 3
                ITEM.height = 2
                ITEM.category = "Weapons"
                ITEM.weaponCategory = "Primary"
                ITEM.bDropOnDeath = ix.config.Get("DropWeaponsOnDeath", false)
                if (v.Throwable) then
                    ITEM.weaponCategory = "Throwable"
                    ITEM.width = 1
                    ITEM.height = 1
                    ITEM.isGrenade = true
                    GrenadeClass[v.ClassName] = true
                elseif (v.NotAWeapon) then
                    ITEM.width = 1
                    ITEM.height = 1
                elseif (v.PrimaryBash) then
                    ITEM.weaponCategory = "Melee"
                    ITEM.width = 1
                    ITEM.height = 2
                elseif (v.HoldType == "pistol" or v.HoldType == "revolver") then
                    ITEM.weaponCategory = "Secondary"
                    ITEM.width = 2
                    ITEM.height = 1
                end
                function ITEM:GetDescription()
                    return self.description
                end
                --// TBD WEAPON REMOVED FROM INV NEED TO REMOVE ATTACHEMENT (Return attachement from removed weapons)
                function ITEM:OnTransferred(oldInventory)

                end
                print("ARC9 Compatibility - "..v.ClassName.." Loaded!")
            end
        end
        print("// ARC9 Compatibility - All Weapons Loaded! //")
        print("// ARC9 Compatibility - Loading Attachments... //")
        for i,v in pairs(ARC9.Attachments) do
            if (!i.Free) then
                local ITEM = ix.item.Register(i, nil, false, nil, true)
                ITEM.name = v.PrintName
                ITEM.description = "A weapon attachement."
                ITEM.model = v.Model or "models/items/arc9/att_plastic_box.mdl"
                ITEM.width = 1
                ITEM.height = 1
                ITEM.att = i
                ITEM.category = "Attachements"
                ITEM.bDropOnDeath = ix.config.Get("DropAttachementsOnDeath", false)
                function ITEM:GetDescription()
                    return self.description
                end
                --// TBD CREATED IN INV
                function ITEM:OnTransferred(oldInventory, newInventory)
                    if (oldInventory and isfunction(oldInventory.GetOwner)) then
                        if (IsValid(oldInventory:GetOwner())) then
                            for _,v in pairs(oldInventory:GetOwner():GetWeapons()) do
                                if(v.Attachments) then
                                    for i,s in pairs(v.Attachments) do
                                        if(s.Installed == ITEM.att) then
                                            v:DetachAllFromSubSlot(i, false)
                                            v:SendWeapon()
                                            v:PostModify()
                                            ARC9:PlayerGiveAtt(oldInventory:GetOwner(), ITEM.att)
                                        end
                                    end 
                                end
                            end
                            ARC9:PlayerTakeAtt(oldInventory:GetOwner(), ITEM.att)
                            ARC9:PlayerSendAttInv(oldInventory:GetOwner())
                        end
                    end
        
                    if (newInventory and isfunction(newInventory.GetOwner)) then
                        if (IsValid(newInventory:GetOwner())) then
                            ARC9:PlayerGiveAtt(newInventory:GetOwner(), ITEM.att)
                            ARC9:PlayerSendAttInv(newInventory:GetOwner())
                        end
                    end
                    return true
                end
                print("// ARC9 Compatibility - "..i.." Loaded! //")
            end
        end
        print("// ARC9 Compatibility - All Attachments Loaded! //")
    end
    print("// ARC9 Compatibility - Has finished loading! //")
end
