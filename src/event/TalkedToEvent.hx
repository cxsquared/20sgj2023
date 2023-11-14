package event;

import ecs.event.IEvent;

class TalkedToEvent implements IEvent {
	public var names:Array<String>;

	public function new(names:Array<String>) {
		this.names = names;
	}
}
