package event;

import ecs.event.IEvent;

class PitchChange implements IEvent {
	public var pitch:Float = 1.0;

	public function new(p:Float) {
		pitch = p;
	}
}
