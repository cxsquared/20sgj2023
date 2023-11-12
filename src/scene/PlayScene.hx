package scene;

import system.HoverHighlightSystem;
import component.HoverHighlight;
import dialogue.event.DialogueHidden;
import system.ClickableSystem;
import dialogue.event.StartNode.StartDialogueNode;
import component.Clickable;
import assets.Assets;
import h2d.Object;
import dialogue.DialogueBoxController;
import ecs.event.EventBus;
import dialogue.DialogueManager;
import hxd.Window;
import ecs.utils.WorldUtils;
import ecs.system.VelocityController;
import constant.Const;
import h2d.col.Bounds;
import h2d.Console;
import h2d.Scene;
import h2d.Bitmap;
import ecs.system.CameraController;
import ecs.component.Velocity;
import ecs.component.Renderable;
import ecs.component.Transform;
import ecs.component.Camera;
import ecs.system.Renderer;
import ecs.scene.GameScene;
import ecs.Entity;
import ecs.World;
import system.PlayerInputController;
import component.Player;

class PlayScene extends GameScene {
	var world:World;
	var eventBus:EventBus;
	var dialogueManager:DialogueManager;
	var dialogueBox:DialogueBoxController;
	var clickableSystem:ClickableSystem;
	var highlightSystem:HoverHighlightSystem;

	public function new(heapsScene:Scene, console:Console) {
		super(heapsScene, console);

		eventBus = new EventBus(console);
		Assets.init(eventBus);

		eventBus.subscribe(StartDialogueNode, function(e) {
			if (clickableSystem != null)
				clickableSystem.canClick = false;

			if (highlightSystem != null)
				highlightSystem.enabled = false;
		});

		eventBus.subscribe(DialogueHidden, function(e) {
			if (clickableSystem != null)
				clickableSystem.canClick = true;

			if (highlightSystem != null)
				highlightSystem.enabled = true;
		});

		loadDialogue();
	}

	public override function init():Void {
		var s2d = getScene();
		this.world = new World();

		var bg = world.addEntity("bg").add(new Renderable(new Bitmap(hxd.Res.party.party_bg.toTile(), this)));
		var player = createPlayer(s2d.width, s2d.height);
		var boyA = world.addEntity("BoyA")
			.add(new Renderable(new Bitmap(hxd.Res.party.boyA.toTile(), this)))
			.add(new Transform(1110, 464, 150, 254))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("PartyBoyA");
				eventBus.publishEvent(event);
			}));
		var boyAHighlight = world.addEntity("BoyAHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.party.boyA_highlight.toTile(), this)))
			.add(boyA.get(Transform))
			.add(new HoverHighlight());

		var girlA = world.addEntity("GirlA")
			.add(new Renderable(new Bitmap(hxd.Res.party.girlA.toTile(), this)))
			.add(new Transform(62, 523, 162, 193))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("PartyGirlA");
				eventBus.publishEvent(event);
			}));

		var girlAHighlight = world.addEntity("GirlAHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.party.girlA_highlight.toTile(), this)))
			.add(girlA.get(Transform))
			.add(new HoverHighlight());

		var girlBBoyB = world.addEntity("GirlBBoyB")
			.add(new Renderable(new Bitmap(hxd.Res.party.girlBBoyB.toTile(), this)))
			.add(new Transform(405, 477, 347, 243))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("PartyGirlBBoyB");
				eventBus.publishEvent(event);
			}));

		var girlBBoyBHighlight = world.addEntity("GirlBBoyBHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.party.girlBBoyB_highlight.toTile(), this)))
			.add(girlBBoyB.get(Transform))
			.add(new HoverHighlight());

		var boyC = world.addEntity("BoyC")
			.add(new Renderable(new Bitmap(hxd.Res.party.boyC.toTile(), this)))
			.add(new Transform(805, 453, 131, 266))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("PartyBoyC");
				eventBus.publishEvent(event);
			}));

		var boyCHighlight = world.addEntity("BoyCHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.party.boyC_highlight.toTile(), this)))
			.add(boyC.get(Transform))
			.add(new HoverHighlight());

		var camera = createCamera(s2d.width, s2d.height, player);
		setupSystems(world, s2d, camera);

		#if debug
		WorldUtils.registerConsoleDebugCommands(console, world);
		#end

		var uiParent = new Object(this);
		dialogueBox = new DialogueBoxController(eventBus, world, uiParent, Game.current.ca, dialogueManager);
	}

	function loadDialogue() {
		dialogueManager = new DialogueManager(eventBus, console);

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
		dialogueManager.load(yarnText, yarnFileNames);
	}

	function createPlayer(sceneWidth:Int, sceneHeight:Int):Entity {
		var playerSize = Const.TileSize;
		var playerX = sceneWidth / 2 - playerSize / 2;
		var playerY = sceneHeight / 2 - playerSize / 2;
		return world.addEntity("Player")
			.add(new Player())
			.add(new Transform(playerX, playerY, playerSize, playerSize))
			.add(new Velocity(0, 0));
	}

	function createCamera(sceneWidth:Int, sceneHeight:Int, target:Entity):Entity {
		var cameraBounds = Bounds.fromValues(0, 0, sceneWidth, sceneHeight);
		return world.addEntity("Camera")
			.add(new Transform())
			.add(new Velocity(0, 0))
			.add(new Camera(target, cameraBounds, sceneWidth / 2, sceneHeight / 2));
	}

	function setupSystems(world:World, scene:Scene, camera:Entity) {
		var window = Window.getInstance();
		clickableSystem = new ClickableSystem(window);
		highlightSystem = new HoverHighlightSystem(window, camera);
		world.addSystem(clickableSystem);
		world.addSystem(new PlayerInputController(Game.current.ca));
		world.addSystem(new VelocityController());
		world.addSystem(highlightSystem);
		world.addSystem(new CameraController(scene, console));
		world.addSystem(new Renderer(camera));
	}

	public override function update(dt:Float):Void {
		dialogueBox.update(dt);
		world.update(dt);
	}
}
