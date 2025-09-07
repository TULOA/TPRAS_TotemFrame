-- =========================================================================================
-- TPRAS Totem Frame (Mists Classic focused)
-- =========================================================================================
local _, playerClass = UnitClass("player")

if playerClass == "SHAMAN" then

	local addonName, _ = ...
	TPRAS_TotemFrameDBPC = TPRAS_TotemFrameDBPC or {}

	-------------------------------------------------
	-- Constants
	-------------------------------------------------
	local PADDING = 4
	local FRAME_HEIGHT = 40
	local FRAME_WIDTH = (FRAME_HEIGHT - PADDING * 2) * 4 + PADDING * 5

	local totemTypes = {
					[1] = { name = "Earth", frameIndex = 2 },
					[2] = { name = "Fire",  frameIndex = 1 },
					[3] = { name = "Water", frameIndex = 3 },
					[4] = { name = "Air",   frameIndex = 4 },
	}

	-------------------------------------------------
	-- Main Frame
	-------------------------------------------------
	local totemFrame = CreateFrame("Frame", "TPRAS_TotemFrame", UIParent, "BackdropTemplate")
	totemFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	totemFrame:SetPoint("CENTER", 0, -200)
	totemFrame:SetMovable(true)
	totemFrame:RegisterForDrag("LeftButton")

	-- Dragging logic (disabled if locked)
	totemFrame:SetScript("OnDragStart", function(self)
					if not TPRAS_TotemFrameDBPC.locked then
									self:StartMoving()
					end
	end)
	totemFrame:SetScript("OnDragStop", function(self)
					self:StopMovingOrSizing()
					local point, _, relPoint, x, y = self:GetPoint()
					TPRAS_TotemFrameDBPC.pos = {point, relPoint, x, y}
	end)

	totemFrame:SetBackdrop({
					bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
					edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
					edgeSize = 12,
					insets = { left = 5, right = 5, top = 5, bottom = 5 },
	})
	totemFrame:SetBackdropColor(0, 0, 0, 0.3)

	-- Restore position & scale on show
	totemFrame:SetScript("OnShow", function(self)
					-- restore position
					local pos = TPRAS_TotemFrameDBPC.pos
					if pos then
									self:ClearAllPoints()
									self:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
					end
					-- restore scale
					local scale = TPRAS_TotemFrameDBPC.scale or 1
					self:SetScale(scale)
	end)

	-------------------------------------------------
	-- Totem Slots (subframes with padding shrink)
	-------------------------------------------------
	totemFrame.slots = {}
	for i = 1, 4 do
					local slotFrame = CreateFrame("Frame", "TPRAS_TotemSlot"..i, totemFrame)
					local quarterWidth = FRAME_WIDTH / 4
					local slotHeight = FRAME_HEIGHT - 6

					slotFrame:SetSize(quarterWidth - 6, slotHeight)
					slotFrame:SetPoint("LEFT", totemFrame, "LEFT", quarterWidth * (i-1) + 3, 0)

					totemFrame.slots[i] = slotFrame
	end

	-------------------------------------------------
	-- Totem Icons
	-------------------------------------------------
	totemFrame.icons = {}
	for i = 1, 4 do
					local parentSlot = totemFrame.slots[i]
					local iconSize = FRAME_HEIGHT - PADDING * 2 - 10

					-- After creating the cooldown icon
					local icon = CreateFrame("Cooldown", "TPRAS_TotemIcon"..i, parentSlot, "CooldownFrameTemplate")
					icon:SetHideCountdownNumbers(true)
					icon:SetSize(iconSize, iconSize)
					icon:SetPoint("CENTER", parentSlot, "CENTER")

					-- Texture (lowest layer)
					icon.iconTexture = icon:CreateTexture(nil, "BACKGROUND")
					icon.iconTexture:SetPoint("TOPLEFT", 2, -2)
					icon.iconTexture:SetPoint("BOTTOMRIGHT", -2, 2)
					icon.iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)

					-- Force cooldown swipe above icon, but below text
					icon:SetFrameLevel(parentSlot:GetFrameLevel() + 1)

					-- Timer text (highest)
					icon.timeText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					icon.timeText:SetPoint("CENTER", icon, "CENTER", 0, 0)
					icon.timeText:SetText("")
					icon.timeText:SetTextColor(1, 1, 0)

					-- Strip extra fontstrings from cooldown template
					for _, r in pairs({icon:GetRegions()}) do
									if r:GetObjectType() == "FontString" then
													r:Hide()
													r.Show = function() end
									end
					end

					icon:Hide()
					totemFrame.icons[i] = icon
	end

	-------------------------------------------------
	-- Update Function
	-------------------------------------------------
	local function UpdateTotemFrame()
					for i = 1, 4 do
									local info = totemTypes[i]
									local totemIndex = info.frameIndex
									local icon = totemFrame.icons[i]

									local haveTotem, _, startTime, duration, iconTexture = GetTotemInfo(totemIndex)
									local timeRemaining = GetTotemTimeLeft(totemIndex)

									if haveTotem and timeRemaining > 0 then
													icon.iconTexture:SetTexture(iconTexture)
													icon:SetCooldown(startTime, duration)
													icon:Show()

													local minutes = math.floor(timeRemaining / 60)
													local seconds = math.floor(timeRemaining % 60)
													if minutes > 0 then
																	icon.timeText:SetText(minutes .. "m")
													else
																	icon.timeText:SetText(seconds)
													end
									else
													icon:Hide()
									end
					end
	end

	-------------------------------------------------
	-- Event Handling
	-------------------------------------------------
	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("PLAYER_TOTEM_UPDATE")
	eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventFrame:SetScript("OnEvent", UpdateTotemFrame)
	UpdateTotemFrame()

	-------------------------------------------------
	-- Options Panel
	-------------------------------------------------
	local options = CreateFrame("Frame", "TPRAS_TotemFrameOptions", InterfaceOptionsFramePanelContainer)
	options.name = "TPRAS Totem Frame"

	local title = options:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("TPRAS Totem Frame Options")

	-- Scale slider
	local scaleSlider = CreateFrame("Slider", "TPRAS_TotemFrameScaleSlider", options, "OptionsSliderTemplate")
	scaleSlider:SetWidth(200)
	scaleSlider:SetHeight(20)
	scaleSlider:SetOrientation("HORIZONTAL")
	scaleSlider:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -40)
	scaleSlider:SetMinMaxValues(0.5, 2)
	scaleSlider:SetValueStep(0.1)
	scaleSlider:SetObeyStepOnDrag(true)
	scaleSlider:SetValue(TPRAS_TotemFrameDBPC.scale or 1)
	totemFrame:SetScale(TPRAS_TotemFrameDBPC.scale or 1)

	_G[scaleSlider:GetName().."Low"]:SetText("0.5")
	_G[scaleSlider:GetName().."High"]:SetText("2.0")
	_G[scaleSlider:GetName().."Text"]:SetText("Frame Scale")

	scaleSlider:SetScript("OnValueChanged", function(self, value)
					TPRAS_TotemFrameDBPC.scale = value
					totemFrame:SetScale(value)
	end)

	-- Lock checkbox
	local lockCheck = CreateFrame("CheckButton", nil, options, "ChatConfigCheckButtonTemplate")
	lockCheck:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -20)
	lockCheck.Text:SetText("Lock Frame (Click-through)")
	lockCheck:SetChecked(TPRAS_TotemFrameDBPC.locked or false)
	lockCheck:SetScript("OnClick", function(self)
					TPRAS_TotemFrameDBPC.locked = self:GetChecked()
					if TPRAS_TotemFrameDBPC.locked then
									totemFrame:EnableMouse(false)
					else
									totemFrame:EnableMouse(true)
					end
	end)

	-- Apply lock state at load
	if TPRAS_TotemFrameDBPC.locked then
					totemFrame:EnableMouse(false)
	else
					totemFrame:EnableMouse(true)
	end

	-- Safe add category for Mists vs Retail
	if InterfaceOptions_AddCategory then
					InterfaceOptions_AddCategory(options)
	elseif Settings and Settings.RegisterCanvasLayoutCategory then
					local category = Settings.RegisterCanvasLayoutCategory(options, options.name)
					Settings.RegisterAddOnCategory(category)
	end
end