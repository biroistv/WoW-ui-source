
if not IsInGlobalEnvironment() then
	-- Don't want to load this file into the secure environment
	return;
end

local ERROR_FORMAT = [[|cffffd200Message:|r|cffffffff %s|r
|cffffd200Time:|r|cffffffff %s|r
|cffffd200Count:|r|cffffffff %s|r
|cffffd200Stack:|r|cffffffff %s|r
|cffffd200Locals:|r|cffffffff %s|r]];

local WARNING_AS_ERROR_FORMAT = [[|cffffd200Message:|r|cffffffff %s|r
|cffffd200Time:|r|cffffffff %s|r
|cffffd200Count:|r|cffffffff %s|r]];

local WARNING_FORMAT = "Lua Warning:\n"..WARNING_AS_ERROR_FORMAT;
local INDEX_ORDER_FORMAT = "%d / %d"

local EXCEPTION_FORMAT = [[%s
Locals: %s]];

local MESSAGE_TYPE_ERROR = 0;
local MESSAGE_TYPE_WARNING = 1;

function message(text, force)
	if ( force or not BasicMessageDialog:IsShown()) then
		BasicMessageDialog.Text:SetText(text);
		BasicMessageDialog:Show();
	end
end

BaseTextTimerMixin = {};

function BaseTextTimerMixin:StartTimer(timeInSeconds, updateFrequency, hideOnFinish, notAbbreviated, formatString)
	if not self.TimerText then
		error("BaseTextTimers require a font string child with parentKey set to TimerText");
		return;
	end

	if timeInSeconds <= 0 then
		self:StopTimer();
		return;
	end

	self:Show();
	self.hideOnFinish = hideOnFinish;
	self.notAbbreviated = notAbbreviated;
	self.formatString = formatString;
	self.currentTime = GetTime();
	self.updateFrequency = updateFrequency;
	self.nextUpdateCountdown = 0;
	self.endTime = self.currentTime + timeInSeconds;
	self:SetScript("OnUpdate", self.OnUpdate);
end

function BaseTextTimerMixin:StopTimer()
	if not self.currentTime then
		-- Timer was never started...just hide it
		self:Hide();
		return;
	end

	self.currentTime = 0;
	self.endTime = 0;
	self.nextUpdateCountdown = 0;
	self:UpdateTimerText();
end

function BaseTextTimerMixin:UpdateTimerText()
	self.remainingTime = max(self.endTime - self.currentTime, 0);

	local formattedTime = SecondsToTime(self.remainingTime, false, self.notAbbreviated, 1, true);
	local timerText = CLASS_TRIAL_TIMER_DIALOG_TEXT_NO_REMAINING_TIME;

	if self.formatString then
		self.TimerText:SetText(self.formatString:format(formattedTime));
	else
		self.TimerText:SetText(formattedTime);
	end

	if self.remainingTime <= 0 then
		self.TimerText:SetText("");
		if self.hideOnFinish then
			self:Hide();
		end
		self:SetScript("OnUpdate", nil);
	end
end

function BaseTextTimerMixin:OnUpdate(elapsed)
	self.nextUpdateCountdown = self.nextUpdateCountdown - elapsed;
	if self.nextUpdateCountdown <= 0 then
		self.nextUpdateCountdown = self.updateFrequency;
		self.currentTime = GetTime();
		self:UpdateTimerText();
	end
end

BaseExpandableDialogMixin = {};

function BaseExpandableDialogMixin:SetupTextureKit(textureKit, textureKitRegionInfo)
	SetupTextureKitsFromRegionInfo(textureKit, self, textureKitRegionInfo);
end

-- override as needed
function BaseExpandableDialogMixin:OnCloseClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
	self:Hide();
end

function BaseExpandableDialogMixin_OnCloseClick(self)
	self:GetParent():OnCloseClick();
end

BaseNineSliceDialogMixin = {};

local textureKitRegionInfo = {
	["ParchmentTop"] = {formatString= "%s-Top", useAtlasSize=true},
	["ParchmentMiddle"] = {formatString="%s-Middle", useAtlasSize = false},
	["ParchmentBottom"] = {formatString="%s-Bottom", useAtlasSize = true},
}

function BaseNineSliceDialogMixin:OnLoad()
	self.Underlay:SetFrameLevel(self:GetFrameLevel() - 1);
	self.Underlay:SetShown(self.showUnderlay);
	NineSliceUtil.ApplyUniqueCornersLayout(self.Border, self.nineSliceTextureKit);
	SetupTextureKitsFromRegionInfo(self.parchmentTextureKit, self.Contents, textureKitRegionInfo)

	self:SetPoint("TOP", UIParent, "TOP", 0, self.topYOffset);

	self.Contents.ParchmentTop:SetPoint("TOP", self, "TOP", self.parchmentXOffset, -self.parchmentYPaddingTop);
	self.Contents.ParchmentBottom:SetPoint("BOTTOM", self, "BOTTOM", self.parchmentXOffset, self.parchmentYPaddingBottom);

	if self.centerBackgroundTexture then
		self.CenterBackground:SetPoint("TOPLEFT", self, "TOPLEFT", self.centerBackgroundXPadding, -self.centerBackgroundYPadding);
		self.CenterBackground:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.centerBackgroundXPadding, self.centerBackgroundYPadding);
		self.CenterBackground:SetAtlas(self.centerBackgroundTexture);
		self.CenterBackground:Show();
	else
		self.CenterBackground:Hide();
	end
end

function BaseNineSliceDialogMixin:Display(title, description, onCloseCvar)
	self.Contents.Title:SetText(title:upper());
	self.Contents.Description:SetText(description);
	self.Contents.DescriptionDuplicate:SetText(description);
	self:Show();
	self.onCloseCvar = onCloseCvar;
end

-- override as needed
function BaseNineSliceDialogMixin:OnCloseClick()
	if self.onCloseCvar then
		SetCVar(self.onCloseCvar, "1");
	end
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
	self:Hide();
end

function BaseNineSliceDialog_OnCloseClick(self)
	self:GetParent():GetParent():OnCloseClick();
end

 ScriptErrorsFrameMixin = {};

function ScriptErrorsFrameMixin:OnLoad()
	self:RegisterForDrag("LeftButton");
	self.index = 0;
	self.seen = {};
	self.order = {};
	self.count = {};
	self.messages = {};
	self.times = {};
	self.locals = {};
	self.warnType = {};
	self.messageCount = 0;
	self.messageLimit = 1000;
end

function ScriptErrorsFrameMixin:OnShow()
	self:Update();
end

function ScriptErrorsFrameMixin:DisplayMessageInternal(msg, warnType, keepHidden, locals, msgKey)
	addframetext("Lua Error: "..msgKey);
	local index = self.seen[msgKey];
	if ( index ) then
		self.count[index] = self.count[index] + 1;
		self.messages[index] = msg;
		self.times[index] = date();
		self.locals[index] = locals;
	else
		tinsert(self.order, msgKey);
		index = #self.order;
		self.count[index] = 1;
		self.messages[index] = msg;
		self.times[index] = date();
		self.seen[msgKey] = index;
		self.locals[index] = locals;
		self.warnType[index] = (warnType or false); --Use false instead of nil

		PrintToDebugWindow(msg);
	end

	if ( not self:IsShown() and not keepHidden ) then
		self.index = index;
		self:Show();
	else
		self:Update();
	end
end

function ScriptErrorsFrameMixin:OnError(msg, warnType, keepHidden)
	-- Example of how debug stack level is calculated
	-- Current stack: [1, 2, 3, 4, 5] (current function is at 1, total current height is 5)
	-- Stack at time of error: [1, 2] (these are currently now index 4 and 5, but at the time of error the stack height is 2)
	-- To calcuate the level to debug (4): curentStackHeight - (errorStackHeight - 1) = 5 - (2 - 1) = 4
	local currentStackHeight = GetCallstackHeight();
	local errorCallStackHeight = GetErrorCallstackHeight();
	local errorStackOffset = errorCallStackHeight and (errorCallStackHeight - 1);
	local debugStackLevel = currentStackHeight - (errorStackOffset or 0);
	local skipFunctionsAndUserdata = true;

	local stack = debugstack(debugStackLevel);
	local locals = debuglocals(debugStackLevel, skipFunctionsAndUserdata);

	-- Prevent K-string locals from causing SetText to fail validation
	locals = string.gsub(locals, "|([kK])", "%1");

	if LogAuroraClient then
		LogAuroraClient("ae", "Lua Error ", "message", msg, "stack", stack);
	end

	self:DisplayMessageInternal(msg, warnType, keepHidden, locals, msg.."\n"..stack);

	-- process any exception after displaying, this ensures frame text is updated
	if (ProcessExceptionClient) then
		ProcessExceptionClient(EXCEPTION_FORMAT:format(msg or "", locals or ""));
	end
end

function ScriptErrorsFrameMixin:OnWarning(msg, warnType, keepHidden)
	self:DisplayMessageInternal(msg, warnType, keepHidden, "", msg);
end

function ScriptErrorsFrameMixin:UpdateTitle(messageType)
	if messageType == MESSAGE_TYPE_ERROR then
		self.Title:SetText(LUA_ERROR);
	elseif messageType == MESSAGE_TYPE_WARNING then
		self.Title:SetText(LUA_WARNING);
	end
end

function ScriptErrorsFrameMixin:DisplayMessage(msg, warnType, keepHidden, messageType)
	self:UpdateTitle(messageType);

	if messageType == MESSAGE_TYPE_ERROR then
		self:OnError(msg, warnType, keepHidden);
	elseif messageType == MESSAGE_TYPE_WARNING then
		self:OnWarning(msg, warnType, keepHidden);
	end

	-- Show a warning if there are too many messages/errors, same handler each time
	self.messageCount = self.messageCount + 1;

	if ( self.messageCount == self.messageLimit ) then
		OnExcessiveErrors();
	end
end

function ScriptErrorsFrameMixin:GetEditBox()
	return self.ScrollFrame.Text;
end

function ScriptErrorsFrameMixin:Update()
	local editBox = self:GetEditBox();
	local index = self.index;
	if ( not index or not self.order[index] ) then
		index = #self.order;
		self.index = index;
	end

	if ( index == 0 ) then
		editBox:SetText("");
		self:UpdateButtons();
		return;
	end

	local warnType = self.warnType[index];

	local text;
	if ( warnType ) then
		local warnFormat = WARNING_FORMAT;
		if ( warnType == LUA_WARNING_TREAT_AS_ERROR ) then
			warnFormat = WARNING_AS_ERROR_FORMAT;
		end

		text = warnFormat:format(self.messages[index], self.times[index], self.count[index]);
	else
		text = ERROR_FORMAT:format(self.messages[index], self.times[index], self.count[index], self.order[index], self.locals[index] or "<none>");
	end

	local parent = editBox:GetParent();
	local prevText = editBox.text;
	editBox.text = text;
	if ( prevText ~= text ) then
		editBox:SetText(text);
		editBox:HighlightText(0);
		editBox:SetCursorPosition(0);
	else
		ScrollingEdit_OnTextChanged(editBox, parent);
	end
	parent:SetVerticalScroll(0);

	self:UpdateButtons();
end

local function GetNavigationButtonEnabledStates(count, index)
	-- Returns indicate whether navigation for "previous" and "next" should be enabled, respectively.
	if count > 1 then
		return index > 1, index < count;
	end

	return false, false;
end

function ScriptErrorsFrameMixin:UpdateButtons()
	local index = self.index;
	local numErrors = self:GetCount();

	local previousEnabled, nextEnabled = GetNavigationButtonEnabledStates(numErrors, index);
	self.PreviousError:SetEnabled(previousEnabled);
	self.NextError:SetEnabled(nextEnabled);

	self.IndexLabel:SetText(INDEX_ORDER_FORMAT:format(index, numErrors));
end

function ScriptErrorsFrameMixin:GetCount()
	return #self.order;
end

function ScriptErrorsFrameMixin:ChangeDisplayedIndex(delta)
	self.index = Clamp(self.index + delta, 0, self:GetCount());
	self:Update();
end

function ScriptErrorsFrameMixin:ShowPrevious()
	self:ChangeDisplayedIndex(-1);
end

function ScriptErrorsFrameMixin:ShowNext()
	self:ChangeDisplayedIndex(1);
end

local function IsErrorCVarEnabled(errorTypeCVar)
	return C_Glue.IsOnGlueScreen() or GetCVarBool(errorTypeCVar);
end

local function DisplayMessageInternal(errorTypeCVar, warnType, msg, messageType)
	local hideErrorFrame = not IsErrorCVarEnabled(errorTypeCVar);
	ScriptErrorsFrame:DisplayMessage(msg, warnType, hideErrorFrame, messageType);

	return msg;
end

function HandleLuaWarning(warnType, warningMessage)
	local cvarName = "scriptWarnings";
	if ( warnType == LUA_WARNING_TREAT_AS_ERROR ) then
		cvarName = "scriptErrors";
	end

	DisplayMessageInternal(cvarName, warnType, warningMessage, MESSAGE_TYPE_WARNING);
end

function HandleLuaError(errorMessage)
	DisplayMessageInternal("scriptErrors", false, errorMessage, MESSAGE_TYPE_ERROR);
end

seterrorhandler(HandleLuaError);
