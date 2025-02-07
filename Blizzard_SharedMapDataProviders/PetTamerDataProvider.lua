PetTamerDataProviderMixin = CreateFromMixins(CVarMapCanvasDataProviderMixin);
PetTamerDataProviderMixin:Init("showTamers");

function PetTamerDataProviderMixin:OnShow()
	CVarMapCanvasDataProviderMixin.OnShow(self);
	
	self:RegisterEvent("SPELLS_CHANGED");
end

function PetTamerDataProviderMixin:OnHide()
	CVarMapCanvasDataProviderMixin.OnHide(self);
	
	self:UnregisterEvent("SPELLS_CHANGED");
end

function PetTamerDataProviderMixin:OnEvent(event, ...)
	CVarMapCanvasDataProviderMixin.OnEvent(self, event, ...);
	
	if event == "SPELLS_CHANGED" then
		self:RefreshAllData();
	end
end

function PetTamerDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("PetTamerPinTemplate");
end

function PetTamerDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData();

	if not C_Minimap.CanTrackBattlePets() or not self:IsCVarSet() then
		return;
	end

	local mapID = self:GetMap():GetMapID();
	local petTamers = C_PetInfo.GetPetTamersForMap(mapID);
	for i, petTamerInfo in ipairs(petTamers) do
		self:GetMap():AcquirePin("PetTamerPinTemplate", petTamerInfo);
	end
end

--[[ Pin ]]--
PetTamerPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_PET_TAMER");

function PetTamerPinMixin:GetTextureSizeInfo(_poiInfo)
	return TextureKitConstants.IgnoreAtlasSize, 16, 16;
end

function PetTamerPinMixin:GetSuperTrackMarkerOffset()
	return -2, 2;
end

function PetTamerPinMixin:OnAcquired(...)
	SuperTrackablePoiPinMixin.OnAcquired(self, ...);
end
