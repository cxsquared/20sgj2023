package assets;

import dialogue.command.ModifyTalkCommand;
import h2d.Console;
import hxyarn.dialogue.Dialogue;
import dialogue.DialogueManager;
import h2d.Font;
import hxd.res.DefaultFont;
import ecs.event.WorldReloaded;
import ecs.event.EventBus;

class Assets {
	public static var worldData:assets.World;
	public static var font:Font;
	public static var dialogue:DialogueManager;

	static var _initDone = false;
	static var eventBus:EventBus;

	public static function init(eventBus:EventBus, console:Console) {
		Assets.eventBus = eventBus;

		if (_initDone)
			return;

		_initDone = true;

		/*
			worldData = new assets.World();

			// LDtk file hot-reloading
			#if debug
			var res = try hxd.Res.load(worldData.projectFilePath.substr(4)) catch (_) null; // assume the LDtk file is in "res/" subfolder
			if (res != null)
				res.watch(() -> {
					// Only reload actual updated file from disk after a short delay, to avoid reading a file being written
					haxe.Timer.delay(function() {
						worldData.parseJson(res.entry.getText());
						Assets.eventBus.publishEvent(new WorldReloaded());
					}, 200);
				});
			#end
		 */

		font = DefaultFont.get();
		font = hxd.Res.font.cozette.toFont();
		font.resizeTo(32);

		dialogue = new DialogueManager(eventBus, console);

		var yarnText = [
			hxd.Res.dialogue.variables.entry.getText(),
			hxd.Res.dialogue.current_time.entry.getText(),
			hxd.Res.dialogue.party.entry.getText(),
			hxd.Res.dialogue.club.entry.getText(),
			hxd.Res.dialogue.coffee.entry.getText(),
		];
		var yarnFileNames = [
			hxd.Res.dialogue.variables.entry.name,
			hxd.Res.dialogue.current_time.entry.name,
			hxd.Res.dialogue.party.entry.name,
			hxd.Res.dialogue.club.entry.name,
			hxd.Res.dialogue.coffee.entry.name,
		];
		dialogue.load(yarnText, yarnFileNames);

		dialogue.addCommandHandler(new ModifyTalkCommand(eventBus));
	}
}
