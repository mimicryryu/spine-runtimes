/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.1
 * 
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 * 
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to install, execute and perform the Spine Runtimes
 * Software (the "Software") solely for internal use. Without the written
 * permission of Esoteric Software (typically granted by licensing Spine), you
 * may not (a) modify, translate, adapt or otherwise create derivative works,
 * improvements of the Software or develop new applications using the Software
 * or (b) remove, delete, alter or obscure any trademarks or any copyright,
 * trademark, patent or other intellectual property or proprietary rights
 * notices on or in the Software, including any copy thereof. Redistributions
 * in binary or source form must include this license and terms.
 * 
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#ifndef SPINE_SKELETONANIMATION_H_
#define SPINE_SKELETONANIMATION_H_

#include <spine/spine.h>
#include <spine/SkeletonRenderer.h>
#include "cocos2d.h"

namespace spine {

/** Mimicry 06-24-2014 --> **/
/* compatible with c99
typedef std::function<void(int trackIndex)> StartListener;
typedef std::function<void(int trackIndex)> EndListener;
typedef std::function<void(int trackIndex, int loopCount)> CompleteListener;
typedef std::function<void(int trackIndex, spEvent* event)> EventListener;
*/
    typedef void (cocos2d::CCObject::*SPINEANI_START_LISTENER) (int trackIndex);
#define spineAniStart_selector(_SELECTOR) (SPINEANI_START_LISTENER)(&_SELECTOR)
    class _StartListener{
    public:
        _StartListener():target(NULL),listener(NULL){}
        void operator()(int trackIndex) {
            if (target) {
                (target->*listener)(trackIndex);
            }
        }
        cocos2d::CCObject* target;
        SPINEANI_START_LISTENER listener;
    };
    typedef _StartListener* StartListener;
    
    
    typedef void (cocos2d::CCObject::*SPINEANI_END_LISTENER) (int trackIndex);
#define spineAniEnd_selector(_SELECTOR) (SPINEANI_END_LISTENER)(&_SELECTOR)
    class _EndListener{
    public:
        _EndListener():target(NULL),listener(NULL){}
        void operator()(int trackIndex) {
            if (target) {
                (target->*listener)(trackIndex);
            }
        }
        cocos2d::CCObject* target;
        SPINEANI_END_LISTENER listener;
    };
    typedef _EndListener* EndListener;
    
    typedef void (cocos2d::CCObject::*SPINEANI_COMPLETE_LISTENER) (int trackIndex, int loopCount);
#define spineAniComplete_selector(_SELECTOR) (SPINEANI_COMPLETE_LISTENER)(&_SELECTOR)
    class _CompleteListener{
    public:
        _CompleteListener():target(NULL),listener(NULL){}
        void operator()(int trackIndex, int loopCount) {
            if (target) {
                (target->*listener)(trackIndex, loopCount);
            }
        }
        cocos2d::CCObject* target;
        SPINEANI_COMPLETE_LISTENER listener;
    };
    typedef _CompleteListener* CompleteListener;
    
    typedef void (cocos2d::CCObject::*SPINEANI_EVENT_LISTENER) (int trackIndex, spEvent* event);
#define spineAniEvent_selector(_SELECTOR) (SPINEANI_EVENT_LISTENER)(&_SELECTOR)
    class _EventListener{
    public:
        _EventListener():target(NULL),listener(NULL){}
        void operator()(int trackIndex, spEvent* event) {
            if (target) {
                (target->*listener)(trackIndex, event);
            }
        }
        cocos2d::CCObject* target;
        SPINEANI_EVENT_LISTENER listener;
    };
    typedef _EventListener* EventListener;
/** <-- Mimicry 06-24-2014 **/


/** Draws an animated skeleton, providing an AnimationState for applying one or more animations and queuing animations to be
  * played later. */
class SkeletonAnimation: public SkeletonRenderer {
public:
	spAnimationState* state;

	static SkeletonAnimation* createWithData (spSkeletonData* skeletonData);
	static SkeletonAnimation* createWithFile (const char* skeletonDataFile, spAtlas* atlas, float scale = 0);
	static SkeletonAnimation* createWithFile (const char* skeletonDataFile, const char* atlasFile, float scale = 0);

	SkeletonAnimation (spSkeletonData* skeletonData);
	SkeletonAnimation (const char* skeletonDataFile, spAtlas* atlas, float scale = 0);
	SkeletonAnimation (const char* skeletonDataFile, const char* atlasFile, float scale = 0);

	virtual ~SkeletonAnimation ();

	virtual void update (float deltaTime);

	void setAnimationStateData (spAnimationStateData* stateData);
	void setMix (const char* fromAnimation, const char* toAnimation, float duration);

	spTrackEntry* setAnimation (int trackIndex, const char* name, bool loop);
	spTrackEntry* addAnimation (int trackIndex, const char* name, bool loop, float delay = 0);
	spTrackEntry* getCurrent (int trackIndex = 0);
	void clearTracks ();
	void clearTrack (int trackIndex = 0);

	StartListener startListener;
	EndListener endListener;
	CompleteListener completeListener;
	EventListener eventListener;
	void setStartListener (spTrackEntry* entry, StartListener listener);
	void setEndListener (spTrackEntry* entry, EndListener listener);
	void setCompleteListener (spTrackEntry* entry, CompleteListener listener);
	void setEventListener (spTrackEntry* entry, EventListener listener);

	virtual void onAnimationStateEvent (int trackIndex, spEventType type, spEvent* event, int loopCount);
	virtual void onTrackEntryEvent (int trackIndex, spEventType type, spEvent* event, int loopCount);

protected:
	SkeletonAnimation ();

private:
	typedef SkeletonRenderer super;
	bool ownsAnimationStateData;

	void initialize ();
};

}

#endif /* SPINE_SKELETONANIMATION_H_ */
