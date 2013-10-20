/******************************************************************************
 * Spine Runtime Software License - Version 1.1
 * 
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms in whole or in part, with
 * or without modification, are permitted provided that the following conditions
 * are met:
 * 
 * 1. A Spine Essential, Professional, Enterprise, or Education License must
 *    be purchased from Esoteric Software and the license must remain valid:
 *    http://esotericsoftware.com/
 * 2. Redistributions of source code must retain this license, which is the
 *    above copyright notice, this declaration of conditions and the following
 *    disclaimer.
 * 3. Redistributions in binary form must reproduce this license, which is the
 *    above copyright notice, this declaration of conditions and the following
 *    disclaimer, in the documentation and/or other materials provided with the
 *    distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#ifndef SPINE_SLOT_H_
#define SPINE_SLOT_H_

#include <spine/Bone.h>
#include <spine/Attachment.h>
#include <spine/SlotData.h>

namespace cocos2d { namespace extension {

struct spSkeleton;

typedef struct spSlot {
	spSlotData* const data;
	struct spSkeleton* const skeleton;
	spBone* const bone;
	float r, g, b, a;
	spAttachment* const attachment;
    spAttachment* const holdAttachment; //** For manual attachment setting. Reserve a "holding" attachment (eg. weapon, slot equipment, etc.). Added By Mimicry. 2013-10-11
    bool isHold; //** For manual attachment setting. All spSkeleton_setAttachment invoke will set this true. Default is false. Added By Mimicry. 2013-10-20
} spSlot;

spSlot* spSlot_create (spSlotData* data, struct spSkeleton* skeleton, spBone* bone);
void spSlot_dispose (spSlot* self);

/* @param attachment May be 0 to clear the attachment for the slot. */
void spSlot_setAttachment (spSlot* self, spAttachment* attachment);

void spSlot_setAttachmentTime (spSlot* self, float time);
float spSlot_getAttachmentTime (const spSlot* self);

void spSlot_setToSetupPose (spSlot* self);

#ifdef SPINE_SHORT_NAMES
typedef spSlot Slot;
#define Slot_create(...) spSlot_create(__VA_ARGS__)
#define Slot_dispose(...) spSlot_dispose(__VA_ARGS__)
#define Slot_setAttachment(...) spSlot_setAttachment(__VA_ARGS__)
#define Slot_setAttachmentTime(...) spSlot_setAttachmentTime(__VA_ARGS__)
#define Slot_getAttachmentTime(...) spSlot_getAttachmentTime(__VA_ARGS__)
#define Slot_setToSetupPose(...) spSlot_setToSetupPose(__VA_ARGS__)
#endif

}} // namespace cocos2d { namespace extension {

#endif /* SPINE_SLOT_H_ */
