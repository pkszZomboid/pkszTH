pkszEpicGen = {}

pkszEpicGen.conversionToEpic = function(item)

	print("conversionToEpic")
	pkszEpicCli.CreateCur = item
	pkszEpicCli.dataConnect("requestSandboxVars",{})

end


pkszEpicGen.doGenerate = function(item)

	if pkszEpicCli.settings.Disabled == true then
		return nil
	end

	local getName = item:getName()
	local getFullType = item:getFullType()
	local getModID = item:getModID()
    local itemModData = item:getModData()
    if not itemModData["pksz"] then
        itemModData["pksz"] = {}
    end

	local thisType = pkszEpicLib.getItemType(item)

	if flgGen == false then
		return nil
	end

	local effectText = "[ "..getName.." ]<br>"..getText("Tooltip_pkszEpic_Item")
	local logText = ""
    local player = getPlayer();
	if player then
	    local username = player:getUsername();
		logText = pkszEpicBuildLogText(logText,"username",username)
	end

	local minMultiplier = pkszEpicCli.settings.SpecImproveMultiplierMin
	local maxMultiplier = pkszEpicCli.settings.SpecImproveMultiplierMax
	local weightReduction = pkszEpicCli.settings.weightReduction
	local flgApplyToBags = pkszEpicCli.settings.ApplyToBags

	-- print("minMultiplier "..pkszEpicCli.settings.SpecImproveMultiplierMin)
	-- print("maxMultiplier "..pkszEpicCli.settings.SpecImproveMultiplierMax)
	-- print("weightReduction "..pkszEpicCli.settings.weightReduction)
	-- print("flgApplyToBags ",pkszEpicCli.settings.ApplyToBags)

	logText = pkszEpicBuildLogText(logText,"Type",thisType)
	logText = pkszEpicBuildLogText(logText,"Name",getFullType)
	logText = pkszEpicBuildLogText(logText,"ModID",getModID)


-- setName
	item:setName(pkszEpicCli.CurName)
	logText = pkszEpicBuildLogText(logText,"setName",pkszEpicCli.CurName)

-- weapon
--------------
	if thisType == "weapon" then
		local dmgBase = 1
		if item:isRanged() == true then

			-- getAimingTime Higher is better
			local modifi = pkszEpicGetValue(item:getAimingTime(),minMultiplier,maxMultiplier,1,"i","p")
			item:setAimingTime(modifi.value)
			effectText = effectText.."<br>AimingTime + "..modifi.mod
			logText = pkszEpicBuildLogText(logText,"+Aiming",modifi.mod)
            itemModData["pksz"]["setAimingTime"] = modifi.mod

			-- getRecoilDelay Lower is better
			modifi = pkszEpicGetValue(item:getRecoilDelay(),minMultiplier,maxMultiplier,1,"i","m")
			item:setRecoilDelay(modifi.value)
			effectText = effectText.."<br>RecoilDelay - "..modifi.mod
			logText = pkszEpicBuildLogText(logText,"-Recoil",modifi.mod)
            itemModData["pksz"]["setRecoilDelay"] = modifi.mod

		else

			dmgBase = 2

		end

		-- getMaxRange
		if item:getMaxRange() ~= 0 then
			local modifi = pkszEpicGetValue(item:getMaxRange(),minMultiplier,maxMultiplier,1,"i","p")
			if modifi.mod == 0 then
				modifi.mod = 0.1
				item:setMaxRange(modifi.value + 0.1)
			else
				item:setMaxRange(modifi.value)
			end
			effectText = effectText.."<br>MaxRange + "..modifi.mod
			logText = pkszEpicBuildLogText(logText,"+Range",modifi.mod)
            itemModData["pksz"]["setMaxRange"] = modifi.mod
		end

		-- setMaxDamage
		local dmgMax = maxMultiplier * dmgBase
		local modifi = pkszEpicGetValue(item:getMaxDamage(),minMultiplier,dmgMax,1,"f","p")
		item:setMaxDamage(modifi.value)
		effectText = effectText.."<br>MaxDamage + "..modifi.mod
		logText = pkszEpicBuildLogText(logText,"+Damage",modifi.mod)
        itemModData["pksz"]["setMaxDamage"] = modifi.mod
	end

-- cloth
--------------
	-- name only

-- bag
--------------
	if thisType == "bag" then
		local bagMax = 5
		local bagMin = 10
		if flgApplyToBags == true then
			bagMax = maxMultiplier
			bagMin = minMultiplier
		end

		-- setCapacity
		local modifi = pkszEpicGetValue(item:getCapacity(),bagMin,bagMax,1,"i","p")
		if modifi.value == item:getCapacity() then
			modifi.value = modifi.value + 1
			modifi.mod = 1
		end
		item:setCapacity(modifi.value)
		effectText = effectText.."<br>Capacity + "..modifi.mod
		logText = pkszEpicBuildLogText(logText,"+Capa",modifi.mod)
        itemModData["pksz"]["setCapacity"] = modifi.mod

		-- setWeightReduction
		if weightReduction > 0 then
			modifi = pkszEpicGetValue(item:getWeightReduction(),0,weightReduction,1,"i","r")
			if modifi.value == item:getWeightReduction() then
				modifi.value = modifi.value + 1
				modifi.mod = 1
			end
			item:setWeightReduction(modifi.value)
			effectText = effectText.."<br>WeightReduction + "..modifi.mod
			logText = pkszEpicBuildLogText(logText,"+WeightReduction",modifi.mod)
            itemModData["pksz"]["setWeightReduction"] = modifi.mod
		end

	end

-- setTooltip
--------------
	effectText = effectText.."<br>"..getText("Tooltip_pkszEpic_Item_info")
	item:setTooltip(effectText)

-- logging
--------------
	pkszEpicCli.clientLogger(logText,"history")

-- clear
--------------
	pkszEpicCli.AdminEpicCur = nil
	pkszEpicCli.CreateCur = nil
	pkszEpicCli.CurName = nil

	return item
end


function pkszEpicGetValue(val,min,max,t,m,s)

	-- print(" pkszEpicGetValue "..val.."/"..min.."/"..max)

	if val == 0 then
		if m == "f" then
			modvalue = 0.05
		end
		if m == "i" then
			modvalue = 1
		end
	else
		if s=="r" then
			s = "p"
			modvalue = ZombRand(min,max)
		else
			modvalue = val * ( ZombRand(min,max) / 100)
		end
	end

	modvalue = modvalue * t

	if m == "f" then
		modvalue = string.format("%3.2f",modvalue)
	end
	if m == "i" then
		modvalue = math.floor(modvalue)
	end

	if s == "p" then
		val = val + modvalue
	else
		val = val - modvalue
		if val < 0 then
			val = 0
		end
	end

	return {mod=modvalue,value=val}

end

function pkszEpicBuildLogText(logText,title,param)
	return logText..title.." / "..param.." | "
end
