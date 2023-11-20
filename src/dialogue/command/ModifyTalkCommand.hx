package dialogue.command;

import event.LevelComplete;
import dialogue.event.LineShown;
import event.ModifyTalk;
import ecs.event.EventBus;

class ModifyTalkCommand implements ICommandHandler {
	public var commandName:String = "talk";

	var eb:EventBus;

	public function new(eb:EventBus) {
		this.eb = eb;
	}

	public function handleCommand(args:Array<String>) {
		var enabled = args[0] == "true" ? true : false;

		var event = new ModifyTalk(enabled);
		eb.publishEvent(event);
	}
}
