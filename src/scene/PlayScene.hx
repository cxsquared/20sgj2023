package scene;

import event.LevelComplete;
import h2d.Layers;
import dialogue.event.DialogueComplete;
import system.SparkMover;
import ecs.utils.Path;
import ecs.utils.WorldUtils;
import h2d.col.Point;
import component.Spark;
import hxsl.Shader;
import shaders.WobbleShader;
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
import hxd.Window;
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
	var dialogueBox:DialogueBoxController;
	var clickableSystem:ClickableSystem;
	var highlightSystem:HoverHighlightSystem;
	var currentInbetweenNode = 0;
	var partyEntites:Array<Entity> = [];

	static var inbetweenNodes = [
		"CurrentTimeStart",
		"CurrentTimeAfterParty",
		"CurrentTimeAfterClub",
		"CurrentTimeAfter",
		"CurrentTimeEnd"
	];

	public function new(heapsScene:Scene, console:Console) {
		super(heapsScene, console);

		eventBus = Game.current.globalEventBus;

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
	}

	function wobbleShadder(bmp:Bitmap):Shader {
		var shader = new WobbleShader();
		shader.speed = 5;
		shader.strength = .05;
		shader.frames = 4;
		shader.texture = bmp.tile.getTexture();
		shader.flowMap = hxd.Res.noise.toTexture();
		return shader;
	}

	public override function init():Void {
		var s2d = getScene();
		var layers = new Layers(this);
		this.world = new World();

		var player = createPlayer(s2d.width, s2d.height);
		var camera = createCamera(s2d.width, s2d.height, player);
		setupSystems(world, s2d, camera);

		#if debug
		WorldUtils.registerConsoleDebugCommands(console, world);
		#end

		var sceneLayer = new Object();
		layers.add(sceneLayer, Const.BackgroundLayerIndex);

		var uiParent = new Object();
		layers.add(uiParent, Const.UiLayerIndex);
		dialogueBox = new DialogueBoxController(eventBus, world, uiParent, Game.current.ca, Assets.dialogue);

		eventBus.publishEvent(new StartDialogueNode(inbetweenNodes[0]));

		eventBus.subscribe(DialogueComplete, function(e) {
			if (e.nodeName == inbetweenNodes[0]) {
				loadParty(s2d, sceneLayer, world);
				currentInbetweenNode++;
			}
		});

		eventBus.subscribe(LevelComplete, function(e) {
			// Party done
			if (e.level == Const.Levels[0]) {
				removeEntitnes(partyEntites);
				eventBus.publishEvent(new StartDialogueNode(inbetweenNodes[1]));
			}
		});
	}

	function spawnSpark(s2d:Scene, parent:Object, level:String):Entity {
		var sparkTile = hxd.Res.images.spark_128_128.toTile();
		var sparkTiles = [
			for (y in 0...Std.int(sparkTile.height / 128))
				for (x in 0...Std.int(sparkTile.width / 128))
					sparkTile.sub(x * 128, y * 128, 128, 128)
		];
		var path = new Path([
			new Point(0, 0),
			new Point(s2d.width, 0),
			new Point(s2d.width, s2d.height),
			new Point(0, s2d.height),
			new Point(0, 0),
		]);

		var sparkAnim = new h2d.Anim(sparkTiles, parent);
		return world.addEntity("spark")
			.add(new Renderable(sparkAnim))
			.add(new Transform(0, 0, 128, 128))
			.add(new Spark(path, function() {
				eventBus.publishEvent(new LevelComplete(level));
			}));
	}

	function loadParty(s2d:Scene, parent:Object, world:World) {
		// BG
		var bg = world.addEntity("bg").add(new Renderable(new Bitmap(hxd.Res.party.party_bg.toTile(), parent)));

		// boy A
		var boyABmp = new Bitmap(hxd.Res.party.boyA.toTile(), parent);
		boyABmp.addShader(wobbleShadder(boyABmp));
		var boyA = world.addEntity("BoyA")
			.add(new Renderable(boyABmp))
			.add(new Transform(1110, 464, 150, 254))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("PartyBoyA");
				eventBus.publishEvent(event);
			}));
		var boyAHighlight = world.addEntity("BoyAHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.party.boyA_highlight.toTile(), parent)))
			.add(boyA.get(Transform))
			.add(new HoverHighlight());

		// Girl A
		var girlABmp = new Bitmap(hxd.Res.party.girlA.toTile(), parent);
		girlABmp.addShader(wobbleShadder(girlABmp));
		var girlA = world.addEntity("GirlA")
			.add(new Renderable(girlABmp))
			.add(new Transform(62, 523, 162, 193))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("PartyGirlA");
				eventBus.publishEvent(event);
			}));

		var girlAHighlight = world.addEntity("GirlAHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.party.girlA_highlight.toTile(), parent)))
			.add(girlA.get(Transform))
			.add(new HoverHighlight());

		// Girl B/Boy B
		var girlBBmp = new Bitmap(hxd.Res.party.girlBBoyB.toTile(), parent);
		girlBBmp.addShader(wobbleShadder(girlBBmp));
		var girlBBoyB = world.addEntity("GirlBBoyB")
			.add(new Renderable(girlBBmp))
			.add(new Transform(405, 477, 347, 243))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("PartyGirlBBoyB");
				eventBus.publishEvent(event);
			}));

		var girlBBoyBHighlight = world.addEntity("GirlBBoyBHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.party.girlBBoyB_highlight.toTile(), parent)))
			.add(girlBBoyB.get(Transform))
			.add(new HoverHighlight());

		// Boy C
		var boyCbmp = new Bitmap(hxd.Res.party.boyC.toTile(), parent);
		boyCbmp.addShader(wobbleShadder(boyCbmp));
		var boyC = world.addEntity("BoyC")
			.add(new Renderable(boyCbmp))
			.add(new Transform(805, 453, 131, 266))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("PartyBoyC");
				eventBus.publishEvent(event);
			}));

		var boyCHighlight = world.addEntity("BoyCHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.party.boyC_highlight.toTile(), parent)))
			.add(boyC.get(Transform))
			.add(new HoverHighlight());

		var spark = spawnSpark(s2d, parent, Const.Levels[0]);

		partyEntites.push(bg);
		partyEntites.push(boyA);
		partyEntites.push(boyAHighlight);
		partyEntites.push(girlA);
		partyEntites.push(girlAHighlight);
		partyEntites.push(girlBBoyB);
		partyEntites.push(girlBBoyBHighlight);
		partyEntites.push(boyC);
		partyEntites.push(boyCHighlight);
	}

	function removeEntitnes(entitnes:Array<Entity>) {
		for (e in entitnes) {
			world.removeEntity(e);
		}
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
		world.addSystem(new SparkMover());
		world.addSystem(new CameraController(scene, console));
		world.addSystem(new Renderer(camera));
	}

	public override function update(dt:Float):Void {
		dialogueBox.update(dt);
		world.update(dt);
	}
}
