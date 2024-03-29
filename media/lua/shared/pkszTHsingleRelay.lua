pkszTHsingle = {}

pkszTHsingle.toServer = function(player,module,command,args)

	print("pkszTHsingle.toServer ----------- ",pkszTHsv.Phase)
	-- print("toServer player ",player)
	-- print("toServer module ",module)
	-- print("toServer command ",command)
	-- print("toServer args ",args)

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
		print("pkszTH debug monitor by Server ------------")
		print("pkszTH progress = " .. pkszTHsv.Progress)
		print("pkszTH mainTick = " .. pkszTHsv.mainTick)
		print("pkszTH startTick "..pkszTHsv.curEvent.startTick)
		print("pkszTH eventTimeout "..pkszTHsv.curEvent.eventTimeout)
		print("pkszTH endTick "..pkszTHsv.curEvent.endTick)
		print("pkszTH Phase sv "..pkszTHsv.Phase)
		print("pkszTH Phase cl "..args.phase)
--		pkszTHmain.getSafehouseList()
    end

end

pkszTHsingle.toClient = function(player,module,command,args)

	print("pkszTHsingle.toClient ----------- ",pkszThCli.phase)
	-- print("onServerCommand module ",module)
	-- print("onServerCommand command ",command)
	-- print("onServerCommand args ",args)

	local player = getPlayer();
    local playerInv = player:getInventory()

	pkszThCli.massege[1] = "no message"
	pkszThCli.massege[2] = ""
	pkszThCli.massege[3] = ""

	-- all member
	if command == "EventInfoShare" then
		pkszThCli.signal = "onSignal"
		-- Get event information
		pkszThCli.curEvent = {}
		pkszThCli.curEvent = args
		pkszThCli.phase = pkszThCli.curEvent.phase
		pkszThCli.masseg = {}
		if not pkszThCli.curEvent.massege then
			pkszThCli.curEvent.massege = {}
			pkszThCli.curEvent.massege[1] = "no message"
			pkszThCli.curEvent.massege[2] = ""
			pkszThCli.curEvent.massege[3] = ""
		end
		pkszThCli.massege[1] = pkszThCli.curEvent.massege[1]
		pkszThCli.massege[2] = pkszThCli.curEvent.massege[2]
		pkszThCli.massege[3] = pkszThCli.curEvent.massege[3]
	end

	-- has pager member
	if command == "IncomingPager" then
		if pkszThCli.isContainsPager() == false then return end
		if pkszThCli.allowRing == true then
			pkszThCli.curEvent = {}
			pkszThCli.curEvent = args
			pkszThCli.phase = pkszThCli.curEvent.phase
			pkszThCli.massege[1] = pkszThCli.curEvent.massege[1]
			pkszThCli.massege[2] = pkszThCli.curEvent.massege[2]
			pkszThCli.massege[3] = pkszThCli.curEvent.massege[3]
			pkszThCli.onMap = true
			-- Play Incoming call
			if pkszThPagerCli.mute == "OFF" then
				ISTimedActionQueue.add(pkszTHpagerAction:new(player))
			end
		end
	end

	-- eventreset
	if command == "eventRestart" then
		if pkszThCli.isContainsPager() == false then return end
		if pkszThCli.allowRing == true then
			pkszThCli.curEvent = {}
			pkszThCli.curEvent = args
			pkszThCli.phase = "wait"
			pkszThCli.onMap = false
			pkszThCli.massege = pkszThCli.curEvent.massege
			pkszThCli.massege[2] = getText("IGUI_pkszTH_restart1")
			pkszThCli.massege[3] = getText("IGUI_pkszTH_restart2")
			if pkszThPagerCli.mute == "OFF" then
				ISTimedActionQueue.add(pkszTHpagerAction:new(player))
			end
		end
	end

	-- forceSuspend
	if command == "forceSuspend" then
		print("pkszTH - Client ERROR : Processing will be force suspend because a fatal error has been detected.")
		pkszThCli.forceSuspend = true
	end

end
