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

local AnimationState = {}

function AnimationState.new (data)
	if not data then error("data cannot be nil", 2) end

	local self = {
		data = data,
		tracks = {},
		events = {},
		onStart = nil, onEnd = nil, onComplete = nil, onEvent = nil,
		timeScale = 1
	}

	local function setCurrent (index, entry)
		local current = self.tracks[index]
		if current then
			current.previous = nil

			if current.onEnd then current.onEnd(index) end
			if self.onEnd then self.onEnd(index) end

			entry.mixDuration = self.data:getMix(current.animation.name, entry.animation.name)
			if entry.mixDuration > 0 then
				entry.mixTime = 0
				entry.previous = current
			end
		end

		self.tracks[index] = entry

		if entry.onStart then entry.onStart(index) end
		if self.onStart then self.onStart(index) end
	end

	function self:update (delta)
		delta = delta * self.timeScale
		for i,current in pairs(self.tracks) do
			if current then
				local trackDelta = delta * current.timeScale
				current.time = current.time + trackDelta
				if current.previous then
					current.previous.time = current.previous.time + trackDelta
					current.mixTime = current.mixTime + trackDelta
				end

				local next = current.next
				if next then
					if current.lastTime >= next.delay then setCurrent(i, next) end
				else
					-- End non-looping animation when it reaches its end time and there is no next entry.
					if not current.loop and current.lastTime >= current.endTime then self:clearTrack(i) end
				end
			end
		end
	end

	function self:apply(skeleton)
		for i,current in pairs(self.tracks) do
			if current then
				local time = current.time
				local lastTime = current.lastTime
				local endTime = current.endTime
				local loop = current.loop
				if not loop and time > endTime then time = endTime end

				local previous = current.previous
				if not previous then
					current.animation:apply(skeleton, current.lastTime, time, loop, self.events)
				else
					local previousTime = previous.time
					if not previous.loop and previousTime > previous.endTime then previousTime = previous.endTime end
					previous.animation:apply(skeleton, previousTime, previousTime, previous.loop, nil)

					local alpha = current.mixTime / current.mixDuration
					if alpha >= 1 then
						alpha = 1
						current.previous = nil
					end
					current.animation:mix(skeleton, current.lastTime, time, loop, self.events, alpha)
				end

				local eventCount = #self.events
				for ii = 1, eventCount, 1 do
					local event = self.events[ii]
					if current.onEvent then current.onEvent(i, event) end
					if self.onEvent then self.onEvent(i, event) end
				end
				for ii = 1, eventCount, 1 do
					table.remove(self.events)
				end

				-- Check if completed the animation or a loop iteration.
				local complete
				if current.loop then
					complete = lastTime % endTime > time % endTime
				else
					complete = lastTime < endTime and time >= endTime
				end
				if complete then 
					local count = math.floor(time / endTime)
					if current.onComplete then current.onComplete(i, count) end
					if self.onComplete then self.onComplete(i, count) end
				end

				current.lastTime = current.time
			end
		end
	end

	function self:clearTracks ()
		for i,current in pairs(self.tracks) do
			self.clearTrack(i)
		end
		self.tracks = {}
	end

	function self:clearTrack (trackIndex)
		local current = self.tracks[trackIndex]
		if not current then return end

		if current.onEnd then current.onEnd(trackIndex) end
		if self.onEnd then self.onEnd(trackIndex) end

		self.tracks[trackIndex] = nil
	end

	function self:setAnimationByName (trackIndex, animationName, loop)
		local animation = self.data.skeletonData:findAnimation(animationName)
		if not animation then error("Animation not found: " + animationName) end
		return self:setAnimation(trackIndex, animation, loop)
	end

	-- Set the current animation. Any queued animations are cleared.
	function self:setAnimation (trackIndex, animation, loop)
		local entry = AnimationState.TrackEntry.new()
		entry.animation = animation
		entry.loop = loop
		entry.endTime = animation.duration
		setCurrent(trackIndex, entry)
		return entry
	end

	function self:addAnimationByName (trackIndex, animationName, loop, delay)
		local animation = self.data.skeletonData:findAnimation(animationName)
		if not animation then error("Animation not found: " + animationName) end
		return self:addAnimation(trackIndex, animation, loop, delay)
	end

	-- Adds an animation to be played delay seconds after the current or last queued animation.
	-- @param delay May be <= 0 to use duration of previous animation minus any mix duration plus the negative delay.
	function self:addAnimation (trackIndex, animation, loop, delay)
		local entry = AnimationState.TrackEntry.new()
		entry.animation = animation
		entry.loop = loop
		entry.endTime = animation.duration

		local last = self.tracks[trackIndex]
		if last then
			while (last.next) do
				last = last.next
			end
			last.next = entry
		else
			self.tracks[trackIndex] = entry
		end

		delay = delay or 0
		if delay <= 0 then
			if last then
				delay = delay + last.endTime - self.data:getMix(last.animation.name, animation.name)
			else
				delay = 0
			end
		end
		entry.delay = delay

		return entry
	end

	-- May return nil.
	function self:getCurrent (trackIndex)
		return self.tracks[trackIndex]
	end

	return self
end

AnimationState.TrackEntry = {}
function AnimationState.TrackEntry.new (data)
	local self = {
		next = nil, previous = nil,
		animation = nil,
		loop = false,
		delay = 0, time = 0, lastTime = -1, endTime = 0,
		timeScale = 1,
		mixTime = 0, mixDuration = 0,
		onStart = nil, onEnd = nil, onComplete = nil, onEvent = nil
	}
	return self
end

return AnimationState
