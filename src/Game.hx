import hxd.res.DefaultFont;
import hxd.Timer;
import hxd.System;
import constant.GameAction;
import constant.Const;
import dn.heaps.input.Controller;
import dn.heaps.input.ControllerAccess;
import ecs.event.ChangeSceneEvent;
import ecs.event.EventBus;
import scene.PlayScene;
import ecs.scene.GameScene;
import hxd.Key;
import h2d.Console;
import h2d.Layers;
import h2d.Text;

class Game extends hxd.App {
	public static var current:Game;

	public var globalEventBus:EventBus;
	public var controller:Controller<GameAction>;
	public var ca:ControllerAccess<GameAction>;

	var scene:GameScene;
	var fps:Text;
	var layer:Layers;
	var console:Console = null;

	public function new() {
		super();
		current = this;
	}

	override function init() {
		s2d.scaleMode = ScaleMode.LetterBox(1280, 720);

		initEngine();
		initController();

		layer = new Layers(s2d);

		#if debug
		fps = new Text(DefaultFont.get());
		fps.visible = false;
		layer.addChildAt(fps, Const.DebugLayerIndex);
		console = new Console(DefaultFont.get());
		layer.addChildAt(console, Const.DebugLayerIndex);
		#end

		globalEventBus = new EventBus(console);
		globalEventBus.subscribe(ChangeSceneEvent, onChangeScene);

		setGameScene(new PlayScene(s2d, console));
	}

	public function onChangeScene(event:ChangeSceneEvent) {
		setGameScene(event.newScene);
	}

	public function setGameScene(gs:GameScene) {
		#if debug
		console.resetCommands();
		#end

		if (scene != null) {
			scene.remove();
		}

		scene = gs;

		scene.init();

		layer.addChildAt(scene, 0);
	}

	public function exit() {
		dispose();

		#if hl
		System.exit();
		#end
	}

	override function update(dt:Float) {
		if (scene != null)
			scene.update(dt);

		#if debug
		if (Key.isPressed(Key.F3)) {
			fps.visible = !fps.visible;
		}
		fps.text = "FPS: " + Timer.fps();
		#end

		#if debug
		if (!console.isActive()) {
		#end
			#if hl
			if (ca.isKeyboardPressed(Key.ESCAPE))
				Game.current.exit();
			#end
		#if debug
		}
		#end
	}

	function initEngine() {
		// Mostly taken from https://github.com/deepnight/gameBase
		// Engine settings
		engine.backgroundColor = 0xff << 24 | 0x111133;
		#if (hl && !debug)
		engine.fullScreen = true;
		#end

		#if (hl && !debug)
		hl.UI.closeConsole();
		// hl.Api.setErrorHandler(onCrash);
		#end

		// Heaps resource management
		#if (hl && debug)
		hxd.Res.initLocal();
		hxd.res.Resource.LIVE_UPDATE = true;
		#else
		hxd.Res.initEmbed();
		#end

		// Sound manager (force manager init on startup to avoid a freeze on first sound playback)
		hxd.snd.Manager.get();
		hxd.Timer.skip(); // needed to ignore heavy Sound manager init frame

		// Framerate
		hxd.Timer.smoothFactor = 0.4;
		hxd.Timer.wantedFPS = Const.FPS;
	}

	function initController() {
		controller = Controller.createFromAbstractEnum(GameAction);

		// Controller
		controller.bindPadLStickXY(GameAction.MoveX, GameAction.MoveY);
		controller.bindPadButtonsAsStickXY(GameAction.MoveX, GameAction.MoveY, DPAD_UP, DPAD_LEFT, DPAD_DOWN, DPAD_RIGHT);
		controller.bindPad(GameAction.Jump, A);
		controller.bindPad(GameAction.Interact, B);

		// Keyboard
		controller.bindKeyboardAsStickXY(MoveX, MoveY, Key.UP, Key.LEFT, Key.DOWN, Key.RIGHT);
		controller.bindKeyboardAsStickXY(MoveX, MoveY, Key.W, Key.A, Key.S, Key.D);
		controller.bindKeyboard(GameAction.Jump, null, [Key.SPACE, Key.Z]);
		controller.bindKeyboard(GameAction.Interact, null, [Key.E, Key.X]);

		controller.setGlobalAxisDeadZone(0.1);

		ca = controller.createAccess();
		// ca.lockCondition = () -> return destoryed || anyInputHasFocus();
	}
}
