local pkszTooltip = {

}
pkszTooltip.render = ISToolTipInv.render

function ISToolTipInv:render()
    local item = self.item
    local itemModData = item:getModData()
    if item and item:getModData()["pksz"] then
        itemModData = item:getModData()["pksz"]
        local tooltip = ""
        if itemModData["setAimingTime"] then
            tooltip = tooltip .. getText("IGUI_ItemEditor_AimingTime") .. " +" .. itemModData["setAimingTime"] .. "<br>"
        end
        if itemModData["setRecoilDelay"] then
            tooltip = tooltip .. getText("IGUI_ItemEditor_RecoilDelay") .. " -" .. itemModData["setRecoilDelay"] .. "<br>"
        end
        if itemModData["setMaxRange"] then
            tooltip = tooltip .. getText("IGUI_ItemEditor_MaxRange") .. " +" .. itemModData["setMaxRange"] .. "<br>"
        end
        if itemModData["setMaxDamage"] then
            tooltip = tooltip .. getText("IGUI_ItemEditor_MaxDmg") .. " +" .. itemModData["setMaxDamage"] .. "<br>"
        end
        if itemModData["setCapacity"] then
            tooltip = tooltip .. getText("IGUI_ItemEditor_Capacity") .. " +" .. itemModData["setCapacity"] .. "<br>"
        end
        if itemModData["setWeightReduction"] then
            tooltip = tooltip .. getText("IGUI_ItemEditor_WeightReduction") .. " +" .. itemModData["setWeightReduction"] .. "<br>"
        end
        item:setTooltip(tooltip)
    end
    pkszTooltip.render(self)
end
