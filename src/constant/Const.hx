package constant;

class Const {
	public static final TileSize = 32;
	public static final BackgroundLayerIndex = 0;
	public static final EnityLayerIndex = 1;
	public static final UiLayerIndex = 2;
	public static final DebugLayerIndex = 3;
	public static final FixedUpdateFps = 30;
	public static final SaveFile = "hiri";

	public static var FPS(get, never):Int;

	public static var Levels = ["Party", "Club", "Coffee"];

	static inline function get_FPS()
		return Std.int(hxd.System.getDefaultFrameRate());
}
