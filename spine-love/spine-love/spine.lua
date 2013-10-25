------------------------------------------------------------------------------
 -- Spine Runtime Software License - Version 1.0
 -- 
 -- Copyright (c) 2013, Esoteric Software
 -- All rights reserved.
 -- 
 -- Redistribution and use in source and binary forms in whole or in part, with
 -- or without modification, are permitted provided that the following conditions
 -- are met:
 -- 
 -- 1. A Spine Essential, Professional, Enterprise, or Education License must
 --    be purchased from Esoteric Software and the license must remain valid:
 --    http://esotericsoftware.com/
 -- 2. Redistributions of source code must retain this license, which is the
 --    above copyright notice, this declaration of conditions and the following
 --    disclaimer.
 -- 3. Redistributions in binary form must reproduce this license, which is the
 --    above copyright notice, this declaration of conditions and the following
 --    disclaimer, in the documentation and/or other materials provided with the
 --    distribution.
 -- 
 -- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 -- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 -- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 -- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 -- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 -- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 -- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 -- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 -- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 -- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ------------------------------------------------------------------------------

spine = {}

spine.utils = require "spine-lua.utils"
spine.SkeletonJson = require "spine-lua.SkeletonJson"
spine.SkeletonData = require "spine-lua.SkeletonData"
spine.BoneData = require "spine-lua.BoneData"
spine.SlotData = require "spine-lua.SlotData"
spine.Skin = require "spine-lua.Skin"
spine.RegionAttachment = require "spine-lua.RegionAttachment"
spine.Skeleton = require "spine-lua.Skeleton"
spine.Bone = require "spine-lua.Bone"
spine.Slot = require "spine-lua.Slot"
spine.AttachmentType = require "spine-lua.AttachmentType"
spine.AttachmentLoader = require "spine-lua.AttachmentLoader"
spine.Animation = require "spine-lua.Animation"
spine.AnimationStateData = require "spine-lua.AnimationStateData"
spine.AnimationState = require "spine-lua.AnimationState"
spine.EventData = require "spine-lua.EventData"
spine.Event = require "spine-lua.Event"
spine.SkeletonBounds = require "spine-lua.SkeletonBounds"

spine.utils.readFile = function (fileName, base)
	local path = fileName
	if base then path = base .. '/' .. path end
	return love.filesystem.read(path)
end

local json = require "spine-love.dkjson"
spine.utils.readJSON = function (text)
	return json.decode(text)
end

spine.Skeleton.failed = {} -- Placeholder for an image that failed to load.

spine.Skeleton.new_super = spine.Skeleton.new
function spine.Skeleton.new (skeletonData, group)
	local self = spine.Skeleton.new_super(skeletonData)

	-- createImage can customize where images are found.
	function self:createImage (attachment)
		return love.graphics.newImage(attachment.name .. ".png")
	end

	-- updateWorldTransform positions images.
	local updateWorldTransform_super = self.updateWorldTransform
	function self:updateWorldTransform ()
		updateWorldTransform_super(self)

		if not self.images then self.images = {} end
		local images = self.images

		if not self.attachments then self.attachments = {} end
		local attachments = self.attachments

		for i,slot in ipairs(self.drawOrder) do
			local attachment = slot.attachment
			if not attachment then
				images[slot] = nil
			elseif attachment.type == spine.AttachmentType.region then
				local image = images[slot]
				if image and attachments[image] ~= attachment then -- Attachment image has changed.
					image = nil
				end
				if not image then -- Create new image.
					image = self:createImage(attachment)
					if image then
						local imageWidth = image:getWidth()
						local imageHeight = image:getHeight()
						attachment.widthRatio = attachment.width / imageWidth
						attachment.heightRatio = attachment.height / imageHeight
						attachment.originX = imageWidth / 2
						attachment.originY = imageHeight / 2
					else
						print("Error creating image: " .. attachment.name)
						image = spine.Skeleton.failed
					end
					images[slot] = image
					attachments[image] = attachment
				end
			end
		end
	end

	function self:draw()
		if not self.images then self.images = {} end
		local images = self.images

		local r, g, b, a = self.r * 255, self.g * 255, self.b * 255, self.a * 255

		for i,slot in ipairs(self.drawOrder) do
			local image = images[slot]
			if image and image ~= spine.Skeleton.failed then
				local attachment = slot.attachment
				local x = slot.bone.worldX + attachment.x * slot.bone.m00 + attachment.y * slot.bone.m01
				local y = slot.bone.worldY + attachment.x * slot.bone.m10 + attachment.y * slot.bone.m11
				local rotation = slot.bone.worldRotation + attachment.rotation
				local xScale = slot.bone.worldScaleX + attachment.scaleX - 1
				local yScale = slot.bone.worldScaleY + attachment.scaleY - 1
				if self.flipX then
					xScale = -xScale
					rotation = -rotation
				end
				if self.flipY then
					yScale = -yScale
					rotation = -rotation
				end
				love.graphics.setColor(r * slot.r, g * slot.g, b * slot.b, a * slot.a)
				if slot.data.additiveBlending then
					love.graphics.setBlendMode("additive")
				else
					love.graphics.setBlendMode("alpha")
				end
				love.graphics.draw(image, 
					self.x + x, 
					self.y - y, 
					-rotation * 3.1415927 / 180,
					xScale * attachment.widthRatio,
					yScale * attachment.heightRatio,
					attachment.originX,
					attachment.originY)
			end
		end

		-- Debug bones.
		if self.debugBones then
			for i,bone in ipairs(self.bones) do
				local xScale
				local yScale
				local rotation = -bone.worldRotation

				if self.flipX then
					xScale = -1
					rotation = -rotation
				else 
					xScale = 1
				end

				if self.flipY then
					yScale = -1
					rotation = -rotation
				else
					yScale = 1
				end

				love.graphics.push()
				love.graphics.translate(self.x + bone.worldX, self.y - bone.worldY)
				love.graphics.rotate(rotation * 3.1415927 / 180)
				love.graphics.scale(xScale, yScale)
				love.graphics.setColor(255, 0, 0)
				love.graphics.line(0, 0, bone.data.length, 0)
				love.graphics.setColor(0, 255, 0)
				love.graphics.circle('fill', 0, 0, 3)
				love.graphics.pop()
			end
		end

		-- Debug slots.
		if self.debugSlots then
			love.graphics.setColor(0, 0, 255, 128)
			for i,slot in ipairs(self.drawOrder) do
				local attachment = slot.attachment
				if attachment and attachment.type == spine.AttachmentType.region then
					local x = slot.bone.worldX + attachment.x * slot.bone.m00 + attachment.y * slot.bone.m01
					local y = slot.bone.worldY + attachment.x * slot.bone.m10 + attachment.y * slot.bone.m11
					local rotation = slot.bone.worldRotation + attachment.rotation
					local xScale = slot.bone.worldScaleX + attachment.scaleX - 1
					local yScale = slot.bone.worldScaleY + attachment.scaleY - 1
					if self.flipX then
						xScale = -xScale
						rotation = -rotation
					end
					if self.flipY then
						yScale = -yScale
						rotation = -rotation
					end
					love.graphics.push()
					love.graphics.translate(self.x + x, self.y - y)
					love.graphics.rotate(-rotation * 3.1415927 / 180)
					love.graphics.scale(xScale, yScale)
					love.graphics.rectangle('line', -attachment.width / 2, -attachment.height / 2, attachment.width, attachment.height)
					love.graphics.pop()
				end
			end
		end
	end

	return self
end

return spine
