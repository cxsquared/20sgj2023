package assets;

import h2d.Font;
import hxd.res.DefaultFont;
import ecs.event.WorldReloaded;
import ecs.event.EventBus;

class Assets {
	public static var worldData:assets.World;
	public static var font:Font;

	static var _initDone = false;
	static var eventBus:EventBus;

	public static function init(eventBus:EventBus) {
		Assets.eventBus = eventBus;

		if (_initDone)
			return;

		_initDone = true;

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

		font = DefaultFont.get();
	}
}
