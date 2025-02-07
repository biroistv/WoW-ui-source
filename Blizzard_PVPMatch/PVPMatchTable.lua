PVPRowMixin = CreateFromMixins(TableBuilderRowMixin);

function PVPRowMixin:SetUseAlternateColor(useAlternateColor)
	self.useAlternateColor = useAlternateColor;
end

function PVPRowMixin:SetBackgroundColor(backgroundColor)
	self.backgroundColor = backgroundColor;
end

local function ApplyColorToBackgrounds(backgrounds, color)
	local r, g, b = color:GetRGB();
	for k, background in pairs(backgrounds) do
		background:SetVertexColor(r, g, b);
	end
end

function PVPRowMixin:Populate(rowData, dataIndex)
	if self.backgroundColor then
		ApplyColorToBackgrounds(self.Backgrounds, self.backgroundColor);
	else
		local color = PVPMatchUtil.GetRowColor(rowData.faction, self.useAlternateColor);
		ApplyColorToBackgrounds(self.Backgrounds, color);
	end
end

PVPHeaderMixin = CreateFromMixins(TableBuilderElementMixin);

function PVPHeaderMixin:Init(sortType, tooltipTitle, tooltipText)
	self.sortType = sortType;
	self.tooltipTitle = tooltipTitle;
	self.tooltipText = tooltipText;
end

function PVPHeaderMixin:OnClick()
	local sortType = self.sortType;
	if sortType then
        SortBattlefieldScoreData(sortType);
	end
	
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
end

function PVPHeaderMixin:OnEnter()
	local tooltipTitle, tooltipText = self.tooltipTitle, self.tooltipText;
	if tooltipTitle or tooltipText then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		if tooltipTitle then
			local wrapText = false;
			GameTooltip_SetTitle(GameTooltip, tooltipTitle, WHITE_FONT_COLOR, wrapText);
		end
		if tooltipText then
			local wrapText = true;
			GameTooltip_AddNormalLine(GameTooltip, tooltipText, wrapText);
		end
		GameTooltip:Show();
	end
end

function PVPHeaderMixin:OnLeave()
	GameTooltip:Hide();
end

PVPHeaderIconMixin = CreateFromMixins(PVPHeaderMixin);

function PVPHeaderIconMixin:Init(textureFileID, sortType)
	PVPHeaderMixin.Init(self, sortType);
	self.textureFileID = textureFileID;

	local icon = self.icon;
	icon:SetTexture(self.textureFileID);
	self:SetSize(icon:GetSize());
end

PVPCellClassMixin = CreateFromMixins(TableBuilderCellMixin);

function PVPCellClassMixin:Populate(rowData, dataIndex)
	local classToken = rowData.classToken;
	local coords = classToken and CLASS_ICON_TCOORDS[classToken];
	local icon = self.icon;
	if coords then
		icon:SetTexCoord(unpack(coords));
		icon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes");
	end
end

function PVPCellClassMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	local className = self.rowData.className or "";
	local talentSpec = self.rowData.talentSpec;
	if talentSpec then
		local tooltipText = format(TALENT_SPEC_AND_CLASS, talentSpec, className);
		GameTooltip_AddNormalLine(GameTooltip, tooltipText, true);
	else
		GameTooltip_AddNormalLine(GameTooltip, className, true);
	end
	GameTooltip:Show();
end

function PVPCellClassMixin:OnLeave()
	GameTooltip:Hide();
end

PVPCellHonorLevelMixin = CreateFromMixins(TableBuilderCellMixin);

function PVPCellHonorLevelMixin:Populate(rowData, dataIndex)
	local honorLevel = rowData.honorLevel;
	if honorLevel then
		local honorRewardInfo = C_PvP.GetHonorRewardInfo(honorLevel);
		local fileID = honorRewardInfo and honorRewardInfo.badgeFileDataID;
		self.icon:SetTexture(fileID);
	end
end

function PVPCellHonorLevelMixin:OnEnter()
	local honorLevel = self.rowData.honorLevel;
	if honorLevel and honorLevel > 0 then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip_AddNormalLine(GameTooltip, HONOR_LEVEL_TOOLTIP:format(honorLevel), true);
		GameTooltip:Show();
	end
end

function PVPCellHonorLevelMixin:OnLeave()
	GameTooltip:Hide();
end

PVPHeaderStringMixin = CreateFromMixins(PVPHeaderMixin);

function PVPHeaderStringMixin:Init(textID, textAlignment, sortType, tooltipTitle, tooltipText)
	PVPHeaderMixin.Init(self, sortType, tooltipTitle, tooltipText)
	self.textID = textID;

	-- Assign the text to get a reference width.
	local text = self.text;
	text:SetJustifyH(textAlignment);
	text:SetText(self.textID);
	
	-- Clamp the width to force wrapping, if applicable.
	local width = text:GetStringWidth();
	local maxColumnWidth = 85;
	text:SetWidth(math.min(width, maxColumnWidth));

	-- Reassign the wrapped width to ensure our region is confined to
	-- the resulting text.
	local wrappedWidth = text:GetWrappedWidth();
	text:SetWidth(wrappedWidth);

	self:SetWidth(wrappedWidth);
end

local function FormatCellColor(frame, rowData, useAlternateColor)
	local color;
	if IsPlayerGuid(rowData.guid) then
		color = WHITE_FONT_COLOR;
	else
		color = PVPMatchUtil.GetCellColor(rowData.faction, useAlternateColor);
	end

	frame:SetVertexColor(color:GetRGB());
end

PVPCellStringMixin = CreateFromMixins(TableBuilderCellMixin);

function PVPCellStringMixin:Init(dataProviderKey, useAlternateColor, isAbbreviated, hasTooltip)
	self.dataProviderKey = dataProviderKey;
	self.useAlternateColor = useAlternateColor;
	self.isAbbreviated = isAbbreviated;
	self.hasTooltip = hasTooltip;
end

function PVPCellStringMixin:Populate(rowData, dataIndex)
	local value = rowData[self.dataProviderKey];
	if self.isAbbreviated then
		value = AbbreviateNumbers(value);
	end

	local text = self.text;
	text:SetText(value);

	FormatCellColor(text, rowData, self.useAlternateColor);
end

function PVPCellStringMixin:OnEnter()
	if self.hasTooltip then
		local value = self.rowData[self.dataProviderKey];
		if value then
			if type(value) == "number" then
				value = BreakUpLargeNumbers(value);
			end

			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip_AddNormalLine(GameTooltip, value, true);
			GameTooltip:Show();
		end
	end
end

function PVPCellStringMixin:OnLeave()
	GameTooltip:Hide();
end

PVPCellNameMixin = CreateFromMixins(TableBuilderCellMixin);

function PVPCellNameMixin:Init(useAlternateColor)
	self.useAlternateColor = useAlternateColor;
	self.text:SetJustifyH("LEFT");
end

function PVPCellNameMixin:Populate(rowData, dataIndex)
	local name = rowData.name;
	local text = self.text;
	text:SetText(name);

	FormatCellColor(text, rowData, self.useAlternateColor);
end

function PVPCellNameMixin:OnEnter()
	local tooltipOffset = 0 - self.text:GetWidth();
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", tooltipOffset, 0);
	
	local className = self.rowData.className or "";
	local raceName = self.rowData.raceName or "";
	GameTooltip_AddNormalLine(GameTooltip, self.rowData.name);
	GameTooltip_AddColoredLine(GameTooltip, raceName.." "..className, WHITE_FONT_COLOR, true);
	GameTooltip:Show();
end

function PVPCellNameMixin:OnLeave()
	GameTooltip:Hide();
end

function PVPCellNameMixin:OnClick(button)
	if button == "RightButton" then
		local contextData =
		{
			unit = self.rowData.guid,
			name = self.rowData.name,
		};
		UnitPopup_OpenMenu("PVP_SCOREBOARD", contextData);
	end
end

PVPSoloShuffleCellNameMixin = CreateFromMixins(PVPCellNameMixin);

local tinyHealerIcon = CreateAtlasMarkup("roleicon-tiny-healer");

function PVPSoloShuffleCellNameMixin:Populate(rowData, dataIndex)
	PVPCellNameMixin.Populate(self, rowData, dataIndex);

	local LFG_ROLE_FLAG_HEALER = 4;
	if rowData.roleAssigned == LFG_ROLE_FLAG_HEALER then
		self.text:SetText(rowData.name.." "..tinyHealerIcon);
	else
		self.text:SetText(rowData.name);
	end

	FormatCellColor(self.text, rowData, self.useAlternateColor);
end

PVPCellStatMixin = CreateFromMixins(TableBuilderCellMixin);

function PVPCellStatMixin:Init(dataProviderKey, useAlternateColor)
	self.dataProviderKey = dataProviderKey;
	self.useAlternateColor = useAlternateColor;
end

local function GetPVPStatData(rowData, pvpStatID)
	local stats = rowData.stats;
	for statsIndex = 1, #stats do
		local stat = stats[statsIndex];
		if stat.pvpStatID == pvpStatID then
			return stat;
		end
	end

	return nil;
end

function PVPCellStatMixin:Populate(rowData, dataIndex)
	local entry = GetPVPStatData(rowData, self.dataProviderKey);
	if entry then
		local value = entry.pvpStatValue;
		if value then
			local text = self.text;
			local iconName = entry.iconName;
			if iconName and iconName ~= "" then
				if value > 0 then
					local markup = CreateAtlasMarkup(iconName,16,16,0,-2);
					local markupCount = FLAG_COUNT_TEMPLATE:format(value);
					local string = markup..markupCount;
					text:SetText(string);
				else
					text:SetText("");
				end
			else
				text:SetText(value);
			end

			FormatCellColor(text, rowData, self.useAlternateColor);
		else
			text:SetText("");
		end
	end
end

PVPSoloShuffleCellStatMixin = CreateFromMixins(PVPCellStatMixin);

function PVPSoloShuffleCellStatMixin:Populate(rowData, dataIndex)
	PVPCellStatMixin.Populate(self, rowData, dataIndex);
end

PVPNewRatingMixin = CreateFromMixins(TableBuilderCellMixin);

function PVPNewRatingMixin:Init(useAlternateColor)
	self.useAlternateColor = useAlternateColor;
end

function PVPNewRatingMixin:Populate(rowData, dataIndex)
	local rating = rowData.rating;
	local ratingChange = rowData.ratingChange;
	local newRating = rating + ratingChange;

	local text = self.text;
	text:SetText(newRating);

	FormatCellColor(text, rowData, self.useAlternateColor);
end

local function ShouldShowRatingColumns()
	-- Ignore Solo Shuffle/Battleground Blitz brawls which use rating for matchmaking purposes
	if C_PvP.IsBrawlSoloShuffle() or C_PvP.IsBrawlSoloRBG() then
		return false;
	end

	return C_PvP.DoesMatchOutcomeAffectRating();
end

function ConstructPVPMatchTable(tableBuilder, useAlternateColor)
	local iconPadding = 2;
	local textPadding = 15;
	
	tableBuilder:Reset();
	tableBuilder:SetDataProvider(C_PvP.GetScoreInfo);
	tableBuilder:SetTableMargins(5);

	local column = tableBuilder:AddColumn();
	column:ConstructHeader("BUTTON", "PVPHeaderIconTemplate", [[Interface/PVPFrame/Icons/prestige-icon-3]], "honorLevel");
	column:ConstrainToHeader();
	column:ConstructCells("FRAME", "PVPCellHonorLevelTemplate");

	column = tableBuilder:AddColumn();
	column:ConstructHeader("BUTTON", "PVPHeaderIconTemplate", [[Interface/PvPRankBadges/PvPRank06]], "class");
	column:ConstrainToHeader(iconPadding);
	column:ConstructCells("FRAME", "PVPCellClassTemplate");

	column = tableBuilder:AddColumn();
	column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", NAME, "LEFT", "name");
	local fillCoefficient = 1.0;
	local namePadding = 4;
	
	local isSoloShuffle = C_PvP.IsSoloShuffle();
	if isSoloShuffle then
		column:ConstructCells("BUTTON", "PVPSoloShuffleCellNameTemplate", useAlternateColor);
	else
		column:ConstructCells("BUTTON", "PVPCellNameTemplate", useAlternateColor);
	end
	column:SetFillConstraints(fillCoefficient, namePadding);

	local function AddPVPStatColumns(cellStatTemplate)
		local statColumns = C_PvP.GetMatchPVPStatColumns();
		table.sort(statColumns, function(lhs,rhs)
			return lhs.orderIndex < rhs.orderIndex;
		end);

		for columnIndex, statColumn in ipairs(statColumns) do
			if strlen(statColumn.name) > 0 then
				column = tableBuilder:AddColumn();
				local sortType = "stat"..columnIndex;
				column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", statColumn.name, "CENTER", sortType, statColumn.tooltipTitle, statColumn.tooltip);
				column:ConstrainToHeader(textPadding);
				column:ConstructCells("FRAME", cellStatTemplate, statColumn.pvpStatID, useAlternateColor);
			end
		end
	end

	if isSoloShuffle then
		local cellStatTemplate = "PVPSoloShuffleCellStatTemplate";
		AddPVPStatColumns(cellStatTemplate);
	end

	if C_PvP.CanDisplayKillingBlows() then
		column = tableBuilder:AddColumn();
		column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", SCORE_KILLING_BLOWS, "CENTER", "kills", KILLING_BLOW_TOOLTIP_TITLE, KILLING_BLOW_TOOLTIP);
		column:ConstrainToHeader(textPadding);
		column:ConstructCells("FRAME", "PVPCellStringTemplate", "killingBlows", useAlternateColor);
	end
	
	if C_PvP.CanDisplayHonorableKills() then
		column = tableBuilder:AddColumn();
		column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", SCORE_HONORABLE_KILLS, "CENTER", "hk", HONORABLE_KILLS_TOOLTIP_TITLE, HONORABLE_KILLS_TOOLTIP);
		column:ConstrainToHeader(textPadding);
		column:ConstructCells("FRAME", "PVPCellStringTemplate", "honorableKills", useAlternateColor);
	end
	 
	if  C_PvP.CanDisplayDeaths() then
		column = tableBuilder:AddColumn();
		column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", DEATHS, "CENTER", "deaths", DEATHS_TOOLTIP_TITLE, DEATHS_TOOLTIP);
		column:ConstrainToHeader(textPadding);
		column:ConstructCells("FRAME", "PVPCellStringTemplate", "deaths", useAlternateColor);
	end

	local isAbbreviated = true;
	local hasTooltip = true;

	if C_PvP.CanDisplayDamage() then
		column = tableBuilder:AddColumn();
		column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", SCORE_DAMAGE_DONE, "CENTER", "damage", DAMAGE_DONE_TOOLTIP_TITLE, DAMAGE_DONE_TOOLTIP);
		column:ConstrainToHeader(textPadding);
		column:ConstructCells("FRAME", "PVPCellStringTemplate", "damageDone", useAlternateColor, isAbbreviated, hasTooltip);
	end

	if C_PvP.CanDisplayHealing() then
		column = tableBuilder:AddColumn();
		column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", SCORE_HEALING_DONE, "CENTER", "healing", HEALING_DONE_TOOLTIP_TITLE, HEALING_DONE_TOOLTIP);
		column:ConstrainToHeader(textPadding);
		column:ConstructCells("FRAME", "PVPCellStringTemplate", "healingDone", useAlternateColor, isAbbreviated, hasTooltip);
	end

	if not isSoloShuffle then
		local cellStatTemplate = "PVPCellStatTemplate";
		AddPVPStatColumns(cellStatTemplate);
	end
	
	local mmrPre = false;
	local ratingPre = false;
	local ratingPost = false;
	local ratingChange = false;
	if ShouldShowRatingColumns() then
		if PVPMatchUtil.IsActiveMatchComplete() then
			-- Skirmish is considered rated for matchmaking reasons.
			ratingChange = not IsArenaSkirmish();
			ratingPost = true;
			mmrPre = C_PvP.IsRatedSoloShuffle() or C_PvP.IsRatedSoloRBG();
		else
			ratingPre = true;
		end
	end

	if mmrPre then
		column = tableBuilder:AddColumn();
		column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", BATTLEGROUND_MATCHMAKING_VALUE, "CENTER", "mmrPre", BATTLEGROUND_MATCHMAKING_VALUE_TOOLTIP_TITLE, BATTLEGROUND_MATCHMAKING_VALUE_TOOLTIP);
		column:ConstrainToHeader(textPadding);
		column:ConstructCells("FRAME", "PVPCellStringTemplate", "prematchMMR", useAlternateColor);
	end

	if ratingPre then
		column = tableBuilder:AddColumn();
		column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", BATTLEGROUND_RATING, "CENTER", "bgratingPre", BATTLEGROUND_RATING_TOOLTIP_TITLE);
		column:ConstrainToHeader(textPadding);
		column:ConstructCells("FRAME", "PVPCellStringTemplate", "rating", useAlternateColor);
	end
	
	if ratingPost then
		column = tableBuilder:AddColumn();
		column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", BATTLEGROUND_NEW_RATING, "CENTER", "bgratingPost", BATTLEGROUND_NEW_RATING_TOOLTIP_TITLE, BATTLEGROUND_NEW_RATING_TOOLTIP);
		column:ConstrainToHeader(textPadding);
		column:ConstructCells("FRAME", "PVPNewRatingTemplate", useAlternateColor);
	end

	local ratingChangeTooltip = isSoloShuffle and RATING_CHANGE_TOOLTIP_SOLO_SHUFFLE or RATING_CHANGE_TOOLTIP;
	if ratingChange then
		column = tableBuilder:AddColumn();
		column:ConstructHeader("BUTTON", "PVPHeaderStringTemplate", SCORE_RATING_CHANGE, "CENTER", "bgratingChange", RATING_CHANGE_TOOLTIP_TITLE, ratingChangeTooltip);
		column:ConstrainToHeader(textPadding);
		column:ConstructCells("FRAME", "PVPCellStringTemplate", "ratingChange", useAlternateColor);
	end

	tableBuilder:Arrange();
end
