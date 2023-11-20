package event;

import ecs.event.IEvent;

class ModifyTalk implements IEvent {
	public var talkEnabled:Bool;

	public function new(te:Bool) {
		talkEnabled = te;
	}
}
