pkszTHmain = {}

pkszTHmain.loadedModCategory = {}

pkszTHmain.enumWTSprint = {"slow3","5","sprint1"}

pkszTHmain.tick = function()


	if isClient() then return end

	if SandboxVars.pkszTHopt.eventDisabled == true then
		return
	end
	if pkszTHsv.forceSuspend == true then
		return
	end

	if pkszTHsv.initialize == 0 then
		pkszTHsv.initialize = 1;
		pkszTHsv.restart()
		pkszTHsv.Phase = "wait"
	end

	pkszTHsv.mainTick = pkszTHsv.mainTick + 1

	if pkszTHsv.Progress == 1 then

		if pkszEpic.initialize == 0 then
			pkszEpic.restart()
		end

		-- send to pager (become unnecessary
		if pkszTHsv.Phase == "notice" then
			pkszTHsv.Phase = "open"
			pkszTHmain.dataConnect('EventInfoShare')
		end

		-- oparate close
		if pkszTHsv.Phase == "close" then
			pkszTHsv.Progress = 0
			pkszTHsv.mainTick = 0
			pkszTHsv.Phase = "wait"
		end

		-- time over
		if pkszTHsv.mainTick > pkszTHsv.curEvent.endTick then
			pkszTHsv.logger("Event time over " ..pkszTHsv.curEvent.EventId,true)
			pkszTHsv.Phase = "close"
			pkszTHsv.Progress = 0
			pkszTHsv.mainTick = 0
			pkszTHlib.saveEventHistory("timeover")
			pkszTHmain.dataConnect('EventInfoShare')
		end
	end

	-- new Event Setup
	if pkszTHsv.Progress == 0 then
		local startEvent = pkszTHmain.newEventSetup()
		if startEvent == "1" then
			pkszTHsv.Phase = "open"
			local sendStr = pkszTHlib.buildSendMessageFormat(pkszTHsv.curEvent)
			pkszTHsv.curEvent.massege = sendStr
			pkszTHmain.dataConnect('IncomingPager')
		end
	end

	-- event version change from sandbox-option
	if SandboxVars.pkszTHopt.eventSelectFileVer ~= pkszTHsv.EventFileVerOpt then
		pkszTHsv.restart()
		pkszTHsv.Phase = "wait"
		local sendString = {}
		local gameTime = pkszTHsv.getGameTime()
		pkszTHsv.curEvent.massege[2] = "..."
		pkszTHsv.curEvent.massege[3] = "..."
		pkszTHmain.dataConnect('eventRestart')
	end

end
Events.EveryTenMinutes.Add(pkszTHmain.tick)
-- Events.EveryOneMinute.Add(pkszTHmain.tick)

pkszTHmain.newEventSetup = function()

	local eventgetFlg = "0"

	if pkszTHsv.mainTick > pkszTHsv.Settings.eventStartWaitTick then
		-- lottery start
		local lot = ZombRand(10)
		if lot <= pkszTHsv.Settings.eventStartChance then
			eventgetFlg = "1"
			if pkszTHmain.getNewEvent() then
				-- pkszTHsv.logger("new eventID = "..pkszTHsv.curEvent.EventId,true)
				pkszTHsv.logger("new event start tick = "..pkszTHsv.curEvent.startTick,true)
				pkszTHsv.logger("new event end tick = "..pkszTHsv.curEvent.endTick,true)
				pkszTHsv.logger("base timeout = "..pkszTHsv.curEvent.eventTimeout,true)
				-- pkszTHsv.logger("Coordinate = "..pkszTHsv.curEvent.Coordinate,true)
				pkszTHsv.logger("InventoryItem = "..pkszTHsv.curEvent.InventoryItem,true)
				-- event mst / pkszTHsv.curEvent = pkszTHsv.Events[myEventId]
				-- Coordinate / pkszTHsv.curEvent.Coordinate = myCordList[setCordNo]
				-- LoadOut / pkszTHsv.curEvent.LoadOut
				pkszTHsv.Progress = 1
				pkszTHsv.Phase = "notice"
				pkszTHlib.saveEventHistory("start")
			else
				pkszTHsv.logger("Event setup failed.",true)
				return "0"
			end
		end
	end

	return eventgetFlg
end

pkszTHmain.getNewEvent = function()

	local changeThis = {}
	local test = nil

	pkszTHsv.logger("---------------------",true)
	pkszTHsv.logger("-- setup new event --",true)

	-- get event id
	local setEventNo = ZombRand(pkszTHsv.EventNum)
	setEventNo = setEventNo + 1
	local myEventId = pkszTHsv.EventIDs[setEventNo]
	local timeAvg = math.floor(SandboxVars.pkszTHopt.eventTickAverage / 10)

	-- set Event ---------------------------------------
	pkszTHsv.curEvent = {}
	pkszTHsv.curEvent.massege = {}
	pkszTHsv.curEvent.massege[1] = "empty"
	pkszTHsv.curEvent.massege[2] = ""
	pkszTHsv.curEvent.massege[3] = ""
	pkszTHsv.curEvent.objBag = nil
	pkszTHsv.curEvent.zedSquare = nil
	pkszTHsv.curEvent.eventNote = ""
	pkszTHsv.curEvent.epics = {}
	local epics = {}

-- next event debug
	if pkszTHsv.nextEventDebug then
		pkszTHsv.logger("nextEventDebug On " .. pkszTHsv.nextEventID,true)
		myEventId = pkszTHsv.nextEventID
	end

-- next anchorON
	if SandboxVars.pkszTHopt.eventIDanchor ~= "" then
		pkszTHsv.logger("eventIDanchor On " .. SandboxVars.pkszTHopt.eventIDanchor,true)
		myEventId = SandboxVars.pkszTHopt.eventIDanchor
	end

	if not myEventId then return end

	if not pkszTHsv.Events[myEventId] then
		pkszTHsv.logger("Error Event not found " .. myEventId,true)
		return false
	end

	-- select EventId
	pkszTHsv.curEvent = pkszTHsv.Events[myEventId]
	pkszTHsv.curEvent.EventId = myEventId

	pkszTHsv.logger("eventID :" ..myEventId,true)
	pkszTHsv.logger("eventDescription :" ..pkszTHsv.curEvent.eventDescription,true)
	pkszTHsv.logger("cordListSelectCD :" ..pkszTHsv.curEvent.cordListSelectCD,true)
	pkszTHsv.logger("eventNote  :" ..pkszTHsv.curEvent.eventNote,true)


	-- get Coordinate
	local myCordList = pkszTHmain.getCordList(pkszTHsv.curEvent.cordListSelectCD)
	if not myCordList then
		pkszTHsv.logger("ERROR cordListSelectCD :"..pkszTHsv.curEvent.cordListSelectCD,true)
		return
	end

	pkszTHsv.curEvent.Coordinate = pkszTHmain.sqCheck(myCordList)
	if pkszTHsv.curEvent.Coordinate == nil then
		pkszTHsv.logger("NOTIS Could not obtain positioning coordinates within 3 times. I'll try again on the next tick ",true)
		return
	end

	-- set coordinate vector3
	pkszTHsv.curEvent.spawnVector = {}
	local cords = pkszTHsv.strSplit(pkszTHsv.curEvent.Coordinate,",")
	pkszTHsv.curEvent.spawnVector.x = tonumber(cords[1])
	pkszTHsv.curEvent.spawnVector.y = tonumber(cords[2])
	pkszTHsv.curEvent.spawnVector.z = tonumber(cords[3])
	pkszTHsv.curEvent.spawnRadius = tonumber(cords[4])
	pkszTHsv.curEvent.outfitGrpCD = cords[5]
	pkszTHsv.curEvent.spawnDesc = cords[6]

	pkszTHsv.logger("getCoordinate :" ..pkszTHsv.curEvent.Coordinate,true)

	-- event type
	if pkszTHsv.curEvent.eventType ~= "nomal" then
		if pkszTHsv.curEvent.eventType ~= "Nomal" then
			pkszTHlib.DetermEventTypeFlags(pkszTHsv.curEvent.eventType)
		end
	end


	-- set event timer
	pkszTHsv.curEvent.startDateTime = pkszTHsv.getGameTime()
	pkszTHsv.curEvent.startTick = pkszTHsv.mainTick
	pkszTHsv.curEvent.endTick = pkszTHsv.mainTick + (pkszTHsv.curEvent.eventTimeout * timeAvg)
	pkszTHsv.curEvent.phase = pkszTHsv.Phase

	-- get load out
	local tempLoadOut = pkszTHloadOut_copy(pkszTHsv.loadOut[pkszTHsv.curEvent.loadOutSelectCD])
	pkszTHsv.curEvent.LoadOut = {}

	-- get random load out
	local cnt = 1
	local lastCnt = 0
	local rGPitems = {}
	local logTxt = ""
	local flgEpic = false
	for key in pairs(tempLoadOut) do
		changeThis = {}

		flgEpic = false
		-- epic
		if string.sub(tempLoadOut[key]["item"], 1, 5) == "epic/" then
			tempLoadOut[key]["item"] = string.match(tempLoadOut[key]["item"], "epic/([%s%d%w%.%_%=%'%,]+)")
			flgEpic = true
		end

		for keyB,valueB in pairs(tempLoadOut[key]) do
			if keyB == "item" then
				local logT = "ItemTypes"
				rGPitems = {}
				if valueB == "random" then
					if tempLoadOut[key]["num"] == "random" then
						local getRandomItem = pkszTHmain.getAllLoadOutRandomItem()
						if getRandomItem then
							if getRandomItem.item == "randomGP" then
								rGPitems = pkszTHmain.getLoadOutRandomGP(getRandomItem["num"])
								if rGPitems then
									for rKey in pairs(rGPitems) do
										pkszTHsv.curEvent.LoadOut[cnt] = rGPitems[rKey]
										logT = "random = R/[RGP]"
										if flgEpic == true then
											table.insert(epics,{name=pkszTHsv.curEvent.LoadOut[cnt]["item"] ,num=pkszTHsv.curEvent.LoadOut[cnt]["num"] ,newname=nil})
											logT = "(epic)"..logT
										end
										logTxt = " : name=".. pkszTHsv.curEvent.LoadOut[cnt]["item"] .." : amount=".. pkszTHsv.curEvent.LoadOut[cnt]["num"]
										pkszTHsv.logger("loadout | "..logT..logTxt,true)
										logT = ""
										cnt = cnt + 1
									end
								end
							elseif getRandomItem.item == "auto" then
								pkszTHsv.curEvent.LoadOut[cnt] = pkszTHmain.getAutoCategoryItem(getRandomItem["num"])
								logT = "random = R/[Auto]"
								cnt = cnt + 1
							else
								pkszTHsv.curEvent.LoadOut[cnt] = getRandomItem
								logT = "random = R/Nomal"
								cnt = cnt + 1
							end
						else
							pkszTHsv.logger("getRandomGP Error ",true)
						end
					else
						changeThis = pkszTHmain.lotRandomItem(tempLoadOut[key]["num"])
						-- print("changeThis item " ..changeThis["item"])
						if changeThis then
							if changeThis.item == "randomGP" then
								rGPitems = pkszTHmain.getLoadOutRandomGP(changeThis["num"])
								if rGPitems then
									for rKey in pairs(rGPitems) do
										pkszTHsv.curEvent.LoadOut[cnt] = rGPitems[rKey]
										logT = "random = [RGP]"
										if flgEpic == true then
											table.insert(epics,{name=pkszTHsv.curEvent.LoadOut[cnt]["item"] ,num=pkszTHsv.curEvent.LoadOut[cnt]["num"] ,newname=nil})
											logT = "(epic)"..logT
										end
										logTxt = " : name=".. pkszTHsv.curEvent.LoadOut[cnt]["item"] .." : amount=".. pkszTHsv.curEvent.LoadOut[cnt]["num"]
										pkszTHsv.logger("loadout | "..logT..logTxt,true)
										logT = ""
										cnt = cnt + 1
									end
								end
							elseif changeThis.item == "auto" then
								pkszTHsv.curEvent.LoadOut[cnt] = pkszTHmain.getAutoCategoryItem(changeThis.num)
								logT = "random = [Auto]"
								cnt = cnt + 1
							else
								pkszTHsv.curEvent.LoadOut[cnt] = changeThis
								logT = "random = ["..tempLoadOut[key]["num"].."]"
								cnt = cnt + 1
							end
						end
					end
				elseif valueB == "randomGP" then
					rGPitems = pkszTHmain.getLoadOutRandomGP(tempLoadOut[key]["num"])
					for rKey in pairs(rGPitems) do
						pkszTHsv.curEvent.LoadOut[cnt] = rGPitems[rKey]
						logT = "randomGP = [RGP]"
						if flgEpic == true then
							table.insert(epics,{name=pkszTHsv.curEvent.LoadOut[cnt]["item"] ,num=pkszTHsv.curEvent.LoadOut[cnt]["num"] ,newname=nil})
							logT = "(epic)"..logT
						end
						logTxt = " : name=".. pkszTHsv.curEvent.LoadOut[cnt]["item"] .." : amount=".. pkszTHsv.curEvent.LoadOut[cnt]["num"]
						pkszTHsv.logger("loadout | "..logT..logTxt,true)
						logT = ""
						cnt = cnt + 1
					end
				elseif valueB == "auto" then
					pkszTHsv.curEvent.LoadOut[cnt] = pkszTHmain.getAutoCategoryItem(tempLoadOut[key]["num"])
					logT = "auto = [Auto]"
					cnt = cnt + 1
				else
					pkszTHsv.curEvent.LoadOut[cnt] = tempLoadOut[key]
					logT = logT.." = "..tempLoadOut[key]["num"]
					cnt = cnt + 1
				end

				-- logging & epic
				if logT ~= "" then
					local checkCnt = cnt - 1
					if lastCnt ~= checkCnt then
						lastCnt = checkCnt
						-- flgEpic
						-- The specification is that even if two Axes are specified as epic, only one will be made epic.
						if flgEpic == true then
							table.insert(epics,{name=pkszTHsv.curEvent.LoadOut[checkCnt]["item"] ,num=pkszTHsv.curEvent.LoadOut[checkCnt]["num"] ,newname=nil})
							logT = "(epic)"..logT
						end

						if pkszTHsv.curEvent.LoadOut[checkCnt] then
							logTxt = " : name=".. pkszTHsv.curEvent.LoadOut[checkCnt]["item"] .." : amount=".. pkszTHsv.curEvent.LoadOut[checkCnt]["num"]
							pkszTHsv.logger("loadout | "..logT..logTxt,true)
						end
					end
				end
			end

		end
	end

	if #epics > 0 then
		pkszTHsv.curEvent.epics = epics
	else
		pkszTHsv.curEvent.epics = nil
	end

	-- get zedOutfit
	-- print("outfitGrpCD ---- " ..pkszTHsv.curEvent.outfitGrpCD)
	-- print("spawnDesc ---- " ..pkszTHsv.curEvent.spawnDesc)

	-- leader
	if not pkszTHsv.zedOutfitGrp[pkszTHsv.curEvent.leaderOutfit] then
		pkszTHsv.logger("ERROR : leaderOutfitGrp CD not found " ..pkszTHsv.curEvent.leaderOutfit,true)
		pkszTHsv.curEvent.leaderOutfitGrp = "None"
		return
	end
	pkszTHsv.curEvent.leaderOutfitGrp = pkszTHsv.zedOutfitGrp[pkszTHsv.curEvent.leaderOutfit]

	-- guards
	if not pkszTHsv.zedOutfitGrp[pkszTHsv.curEvent.outfitGrpCD] then
		pkszTHsv.logger("ERROR : zedOutfitGrp CD not found " ..pkszTHsv.curEvent.outfitGrpCD,true)
		pkszTHsv.curEvent.outfitGrpCD = "None"
		return
	end

	pkszTHsv.curEvent.zedOutfitGrp = pkszTHsv.zedOutfitGrp[pkszTHsv.curEvent.outfitGrpCD]
	pkszTHsv.logger("zedOutfitGrp = "..pkszTHsv.curEvent.outfitGrpCD,true)

	return true

end

pkszTHmain.sqCheck = function(myCordList)

	for i=1,3 do

		local setCordNo = ZombRand(#myCordList) + 1
		local Coordinate = myCordList[setCordNo]

		-- next event debug
		if pkszTHsv.nextEventDebug == true then
			if pkszTHsv.nextEventCoordinate ~= nil then
				pkszTHsv.logger("nextEventDebug On " .. pkszTHsv.nextEventCoordinate,true)
				Coordinate = pkszTHsv.nextEventCoordinate
			end
		end

		local cords = pkszTHsv.strSplit(Coordinate,",")
		local sq = getWorld():getCell():getGridSquare(tonumber(cords[1]), tonumber(cords[2]), 0);

		if SafeHouse.getSafeHouse(sq) == nil then
			pkszTHsv.logger("setCordNo = " ..setCordNo.. " / " ..#myCordList,true)
			return Coordinate
		else
			pkszTHsv.logger("The coordinates I tried to place were a safe house. try "..i.." : "..Coordinate,true)
		end
	end

	return nil

end

-- Use of this feature is not recommended
pkszTHmain.getAutoCategoryItem = function(data)

	if not data then
		pkszTHsv.logger("Nothing Auto category",true)
		return
	end

	-- info = {modId=modID, subject=key, param=rec2[1]}
	local info = pkszTHsv.autoCategorys[data]
	if not info then
		pkszTHsv.logger("ERROR auto category not found :"..data,true)
		return {item="Base.Frog",num=1}
	end


	if info.modId == "vanilla" then
		if not pkszTHmain.loadedModCategory[data] then
			pkszTHmain.loadedModCategory[data] = {}
			pkszTHmain.loadedModCategory[data] = pkszTHmain.getAutoCategoryListBaseItem(info)
		end
	else
		if not pkszTHmain.loadedModCategory[data] then
			pkszTHmain.loadedModCategory[data] = {}
			pkszTHmain.loadedModCategory[data] = pkszTHmain.getAutoCategoryList(info)
		end
	end

	local lots = pkszTHmain.loadedModCategory[data]
	local chois = ZombRand(#lots) + 1
	local itemFullName = pkszTHmain.loadedModCategory[data][chois]
	local myItems = {item=itemFullName,num=1}

	return myItems

end

-- If category items are not listed, list them.
pkszTHmain.getAutoCategoryList = function(info)
	print("--------- pkszTHmain.getAutoCategoryList --------------")
	-- print(info.modId .." / ".. info.subject .." / ".. info.param)
	local items = getAllItems();
	local result = {}
	local cnt = 1

	for i=0,items:size()-1 do
		local item = items:get(i);
		if not item:getObsolete() and not item:isHidden() then
			if item:getModID() == info.modId then
				-- type
				if info.subject == "DisplayCategory" then
	 				if item:getDisplayCategory() == info.param then
						result[cnt] = item:getFullName()
						cnt = cnt + 1
	 				end
				end
				-- display category
				if info.subject == "Type" then
	 				if item:getTypeString() == info.param then
						result[cnt] = item:getFullName()
						cnt = cnt + 1
	 				end
				end
			end
		end
	end

	if #result == 0 then
		pkszTHsv.logger("AutoCategory zero :".. info.modId .." / ".. info.param .." cnt = "..#result,true)
		pkszTHsv.logger("Error ".. info.param .." Zero , so add the frog.",true)
		result[1] = "Base.Frog"
	else
		pkszTHsv.logger("Create AutoCategory Cash :".. info.modId .." / ".. info.param .." cnt = "..#result,true)
	end

	return result
end

pkszTHmain.getAutoCategoryListBaseItem = function(info)
	print("--------- pkszTHmain.getAutoCategoryListBaseItem --------------")
	-- print(info.modId .." / ".. info.subject .." / ".. info.param)
	local items = getAllItems();
	local result = {}
	local cnt = 1
	for i=0,items:size()-1 do
		local item = items:get(i);
		if not item:getObsolete() and not item:isHidden() then
			-- type
			if info.subject == "DisplayCategory" then
 				if item:getDisplayCategory() == info.param then
					result[cnt] = item:getFullName()
					cnt = cnt + 1
 				end
			end
			-- display category
			if info.subject == "Type" then
 				if item:getTypeString() == info.param then
					result[cnt] = item:getFullName()
					cnt = cnt + 1
 				end
			end
		end
	end

	if #result == 0 then
		pkszTHsv.logger("AutoCategory zero :".. info.modId .." / ".. info.param .." cnt = "..#result,true)
		pkszTHsv.logger("An error will occur, so add the frog.",true)
		result[1] = "Base.Frog"
	else
		pkszTHsv.logger("Create AutoCategory Cash :".. info.modId .." / ".. info.param .." cnt = "..#result,true)
	end

	return result
end

pkszTHmain.getCordList = function(cordText)

	-- print("cordText "..cordText)
	local newcordList = {}
	if string.find(cordText,",") then
		-- print("multi cordlist")
		local ml = pkszTHsv.strSplit(cordText,",")
		for key,val in pairs(ml) do
			if not pkszTHsv.CordinateList[val] then
				pkszTHsv.logger("ERROR : CordinateList cd not found "..val,true)
				pkszTHsv.curEvent.cordListSelectCD = "error"
			end
			newcordList = pkszTHsv.merge_tables(newcordList,pkszTHsv.CordinateList[val])
		end
		return newcordList
	else
		-- print("single cordlist")
		if not pkszTHsv.CordinateList[cordText] then
			pkszTHsv.logger("ERROR : CordinateList cd not found "..cordText,true)
			pkszTHsv.curEvent.cordListSelectCD = "error"
		end
		return pkszTHsv.CordinateList[cordText]
	end

end

pkszTHmain.getAllLoadOutRandomItem = function()

	local loadOutRandomNo = ZombRand(pkszTHsv.loadOutRandomIndexCnt) + 1
	local takeThis = pkszTHsv.loadOutRandomIndex[loadOutRandomNo]
	return takeThis

end

pkszTHmain.getLoadOutRandomGP = function(rGPCD)

	if not pkszTHsv.loadOutRandomGP[rGPCD] then
		pkszTHsv.logger("ERROR : loadOutRandomGP id not found " ..rGPCD,true)
		return
	end

	local myArray = pkszTHsv.loadOutRandomGP[rGPCD]
	local chois = ZombRand(#myArray) + 1
	local getMyItem = pkszTHsv.loadOutRandomGP[rGPCD][chois]
	local myItems = pkszTHsv.getRandomGPLineSplit(getMyItem)

	return myItems

end

pkszTHmain.lotRandomItem = function(grpID)

	if not pkszTHsv.loadOutRandom[grpID] then
		pkszTHsv.logger("ERROR : loadOutRandom id not found " ..grpID,true)
		return
	end

	local myLots = pkszTHsv.loadOutRandom[grpID]
	local chois = ZombRand(#myLots) + 1

	local myItem = pkszTHsv.loadOutRandom[grpID][chois]

	-- print("------ /// lotRandomItem grpID " ..grpID)
	-- print("------ /// chois random no "..chois)

	return myItem
end


-- Why does the order change?
-- sendClientCommand(player, "pkszTHctrl", act, pkszThCli.curEvent);
local function onServerCommand(module,command,player,args)

	if module ~= "pkszTHctrl" then return end

    if command == "doSpawnObject" then
		if pkszTHsv.Phase == "open" then
			pkszTHsv.Phase = "enter"
			pkszTHmain.spawnZombie()
			pkszTHmain.syncLoadout()
			pkszTHmain.dataConnect('EventInfoShare')
		end
    end

    if command == "doClose" then
		pkszTHsv.Phase = "wait"
		pkszTHsv.Progress = 0
		pkszTHsv.mainTick = 0
		pkszTHsv.logger("Event Clear " ..pkszTHsv.curEvent.EventId,true)
	    local username = player:getUsername();
		pkszTHlib.saveEventHistory("Clear:"..username)
		pkszTHmain.dataConnect('EventInfoShare')
    end

    if command == "doSpawnObjectSurely" then
		print("doSpawnObjectSurely -- debug only ----------")
		-- test
		pkszTHsv.Phase = "enter"
		pkszTHmain.syncLoadout()
		pkszTHmain.spawnZombie()
		pkszTHmain.dataConnect('EventInfoShare')
    end

    if command == "requestCurEvent" then
		-- print("pkszTH catch requestCurEvent")
		pkszTHmain.dataConnect('EventInfoShare')
    end

    if command == "initRequest" then
		-- print("pkszTH catch initRequest")
		pkszTHmain.dataConnect('EventInfoShare')
    end

    if command == "debugPrint" then

		local square = getSquare(
			player:getX(),
			player:getY(),
			player:getZ()
		)

		local spawnSpace = getWorld():getCell():getGridSquare(player:getX(), player:getY(), 0);
		print(player:getX())
		print(square)
		print("safehouse ",SafeHouse.getSafeHouse(spawnSpace))

		print("pkszTH debug monitor by Server ------------")
		print("pkszTH progress = " .. pkszTHsv.Progress)
		print("pkszTH mainTick = " .. pkszTHsv.mainTick)
		print("pkszTH startTick "..pkszTHsv.curEvent.startTick)
		print("pkszTH eventTimeout "..pkszTHsv.curEvent.eventTimeout)
		print("pkszTH endTick "..pkszTHsv.curEvent.endTick)
		print("pkszTH Phase sv "..pkszTHsv.Phase)
		print("pkszTH Phase cl "..args.phase)
--		pkszTHmain.getSafehouseList()
		print("-------------------- ")
		print(" pager drop rate ",SandboxVars.pkszTHopt.PagerDropRate)
	end

end
Events.OnClientCommand.Add(onServerCommand)


-- spawnZed
pkszTHmain.spawnZombie = function()

	local density = tonumber(pkszTHsv.curEvent.HordeDensity)
	local radius = tonumber(pkszTHsv.curEvent.spawnRadius)
	local squareX = pkszTHsv.curEvent.spawnVector.x
	local squareY = pkszTHsv.curEvent.spawnVector.y
	local squareZ = pkszTHsv.curEvent.spawnVector.z

	-- 1 Zed down in the center (Leader)
	local LDoutfits = pkszTHsv.curEvent.leaderOutfitGrp
	local LDoutfitNo = ZombRand(#LDoutfits) + 1
	local LDOutfit = LDoutfits[LDoutfitNo]
	addZombiesInOutfit(squareX, squareY, squareZ, 1,LDOutfit["item"], tonumber(LDOutfit["num"]), true, true, true, true, 1)

	-- is eventType zombiewalk
	local isCustomWalk = nil
	local customWalk = {}
	if SandboxVars.pkszTHopt.walkSpeedChange == true then
		if pkszTHsv.curEvent.eventTags then
			if pkszTHsv.curEvent.eventTags["zombiewalk"] then
			pkszTHsv.logger("Enable Zombies walkspeed change ->"..pkszTHsv.curEvent.eventTags["zombiewalk"],true)
				isCustomWalk = pkszTHsv.strSplit(pkszTHsv.curEvent.eventTags["zombiewalk"],",")
				local walkSum = 0
				if #isCustomWalk == 3 then
					for i=1,#isCustomWalk do
						walkSum = walkSum + tonumber(isCustomWalk[i])
						customWalk[i] = tonumber(isCustomWalk[i])
					end
					local sumUp = 0
					for i=1,#isCustomWalk do
						if customWalk[i] > 0 then
							customWalk[i] = math.floor(customWalk[i] * 100 / walkSum)
							customWalk[i] = customWalk[i] + sumUp
						else
							customWalk[i] = 0
						end
						sumUp = customWalk[i]
					end
				end
			end
		end
	end

	local square = getSquare(
		pkszTHsv.curEvent.spawnVector.x,
		pkszTHsv.curEvent.spawnVector.y,
		pkszTHsv.curEvent.spawnVector.z
	)

	-- Spawn Horde
	if density > 0 then
		local outfits = pkszTHsv.curEvent.zedOutfitGrp
		if not isServer() then
			if pkszTHsv.curEvent.outfitGrpCD == "None" then
				outfits = pkszTHsv.zedOutfitGrp["sNone"]
				pkszTHsv.logger("Changed single None -> sNone",true)
			end
		end
		for i=1,density do
			local outfitNo = ZombRand(#outfits) + 1
			local thisOutfit = outfits[outfitNo]
			local x = ZombRand(squareX - radius, squareX + radius + 1)
			local y = ZombRand(squareY - radius, squareY + radius + 1)
			-- print("x= "..x.." y= "..y.." sqZ "..squareZ.." zed "..thisOutfit["item"].." femaleChance "..thisOutfit["num"])
			local zeds = addZombiesInOutfit(x, y, squareZ, 1, tostring(thisOutfit["item"]), tonumber(thisOutfit["num"]), false, false, false, false, 1)
			local zed = zeds:get(0)

			if isCustomWalk ~= nil then
				local spdtag = ZombRand(100)
				local spd = ""
				for i=1,#isCustomWalk do
					if customWalk[i] ~= 0 then
						if spdtag <= customWalk[i] then
							spd = pkszTHmain.enumWTSprint[i]
							-- print("this speed "..customWalk[i].." / "..spdtag.." : "..spd)
							zed:setWalkType(spd)
							break
						end
					end
				end
			end

		end
	end

	pkszTHsv.logger("spawnLeader "..LDOutfit["item"],true)
	pkszTHsv.logger("spawnZed "..squareX.."-"..squareY.."-"..squareZ.." Density "..density.." Radius "..radius,true)

end

-- loadout sync
pkszTHmain.syncLoadout = function()

	local item = InventoryItemFactory.CreateItem(pkszTHsv.curEvent.InventoryItem)
	if not item then
		item = InventoryItemFactory.CreateItem("Base.Bag_ToolBag")
		pkszTHsv.logger("Changed to Base.Bag_ToolBag because bag creation failed "..pkszTHsv.curEvent.InventoryItem,true)
	end

	local epics = nil
	if pkszTHsv.curEvent.epics ~= nil then
		epics = pkszTHsv.curEvent.epics
	end
	local newName = "Base.Frog"

	for key in pairs(pkszTHsv.curEvent.LoadOut) do
		for keyB,valueB in pairs(pkszTHsv.curEvent.LoadOut[key]) do
			if keyB == "item" then

				local inBag = InventoryItemFactory.CreateItem(valueB)

				if instanceof(inBag, "InventoryItem") then
					-- epic nameing
					if epics ~= nil then
						for key,value in pairs(epics) do
							if epics[key]["newname"] == nil then
								if epics[key]["name"] == valueB then
									if pkszEpicMain.CreateItemNameWrap(inBag) then
										epics[key]["newname"] = pkszEpicMain.CreateItemNameWrap(inBag)
										-- print("get new name "..epics[key]["newname"])
									end
								end
							end
						end
					end

					item:getItemContainer():AddItems( inBag ,tonumber(pkszTHsv.curEvent.LoadOut[key]["num"]) );

				else

					item:getItemContainer():AddItems( "Base.Frog" ,1 );
					pkszTHsv.logger("Changed it to a frog because I failed to get the item.",true)

				end

			end
		end
	end

	if pkszTHsv.curEvent.epics ~= nil then
		pkszTHsv.curEvent.epics = epics
	end

	-- This "transmitCompleteItemToServer" fucking broken
	-- local inv = square:AddWorldInventoryItem(pkszTHsv.curEvent.InventoryItem, 0,0,0)
	-- inv:getWorldItem():transmitCompleteItemToServer()
	-- --------------------------xxxxxx

	--- Solved by send isoObject to client
	pkszTHsv.curEvent.objBag = item

end

pkszTHmain.dataConnect = function(act)

	if isClient() then return end
	-- print("isServer ",isServer())
	pkszTHsv.logger(pkszTHsv.Phase .. " / to client send message " .. act ,true)
	pkszTHsv.curEvent.phase = pkszTHsv.Phase
	if isServer() then
		sendServerCommand('pkszTHpager', act, pkszTHsv.curEvent)
	else
		pkszTHsingle.toClient(player, "pkszTHctrl", act, pkszTHsv.curEvent);
	end

end

function pkszTHloadOut_copy(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = {}
		t2[k]["item"] = v.item
		t2[k]["num"] = v.num
	end
	return t2
end
