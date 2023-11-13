package event;

import ecs.event.IEvent;

class LevelComplete implements IEvent {
	public var level:String;

	public function new(level:String) {
		this.level = level;
	}
}
