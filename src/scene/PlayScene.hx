package scene;

import system.TimerMaskSystem;
import component.TimerMask;
import h2d.Graphics;
import h2d.filter.Mask;
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
	var currentEntities:Array<Entity> = [];

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

		eventBus.subscribe(DialogueComplete, function(e) {
			if (e.nodeName == inbetweenNodes[0]) {
				dialogueBox.moveTo(4, 4);
				loadParty(s2d, sceneLayer, world);
				currentInbetweenNode++;
				return;
			}

			if (e.nodeName == inbetweenNodes[1]) {
				dialogueBox.moveTo(4, 4);
				loadClub(s2d, sceneLayer, world);
				currentInbetweenNode++;
				return;
			}
		});

		eventBus.subscribe(LevelComplete, function(e) {
			// Party done
			if (e.level == Const.Levels[0]) {
				Assets.dialogue.stop();
				removeEntitnes();
				haxe.Timer.delay(function() {
					startInbetween();
				}, 1000);
				return;
			}

			if (e.level == Const.Levels[1]) {
				Assets.dialogue.stop();
				removeEntitnes();
			}
		});

		eventBus.publishEvent(new DialogueComplete(inbetweenNodes[1]));
		// startInbetween();
	}

	function wobbleShadder(bmp:Bitmap, strength:Float = .05):Shader {
		var shader = new WobbleShader();
		shader.speed = 5;
		shader.strength = strength;
		shader.frames = 4;
		shader.texture = bmp.tile.getTexture();
		shader.flowMap = hxd.Res.noise.toTexture();
		return shader;
	}

	function startInbetween() {
		dialogueBox.moveTo(4, getScene().height / 2 - dialogueBox.getSize().height / 2, TopRight);
		eventBus.publishEvent(new StartDialogueNode(inbetweenNodes[currentInbetweenNode]));
	}

	function loadClub(s2d:Scene, parent:Object, world:World) {
		// BG
		var bgBmp = new Bitmap(hxd.Res.club.club_bg.toTile(), parent);
		var bg = world.addEntity("bg").add(new Renderable(bgBmp));

		currentEntities.push(bg);

		// girlC girl D
		var girlCgirlDBmp = new Bitmap(hxd.Res.club.girlCgirlD.toTile(), parent);
		girlCgirlDBmp.addShader(wobbleShadder(girlCgirlDBmp));
		var girlCgirlD = world.addEntity("girlCgirlD")
			.add(new Renderable(girlCgirlDBmp))
			.add(new Transform(370, s2d.getSize().height - girlCgirlDBmp.getSize().height, girlCgirlDBmp.getSize().width, girlCgirlDBmp.getSize().height))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("ClubGirlCGirlD");
				eventBus.publishEvent(event);
			}));
		var girlCgirlDHighlight = world.addEntity("GirlCGirlDHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.club.girlCgirlD_highlight.toTile(), parent)))
			.add(girlCgirlD.get(Transform))
			.add(new HoverHighlight());

		currentEntities.push(girlCgirlD);
		currentEntities.push(girlCgirlDHighlight);

		// Girl A
		var girlABmp = new Bitmap(hxd.Res.club.girlA.toTile(), parent);
		girlABmp.addShader(wobbleShadder(girlABmp));
		var girlA = world.addEntity("GirlA")
			.add(new Renderable(girlABmp))
			.add(new Transform(997, s2d.getSize().height - girlABmp.getSize().height, girlABmp.getSize().width, girlABmp.getSize().height))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("ClubGirlA");
				eventBus.publishEvent(event);
			}));

		var girlAHighlight = world.addEntity("GirlAHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.club.girlA_highlight.toTile(), parent)))
			.add(girlA.get(Transform))
			.add(new HoverHighlight());

		currentEntities.push(girlA);
		currentEntities.push(girlAHighlight);

		// Girl B/Boy C
		var girlBBmp = new Bitmap(hxd.Res.club.girlABoyC.toTile(), parent);
		girlBBmp.addShader(wobbleShadder(girlBBmp));
		var girlBBoyB = world.addEntity("GirlBBoyC")
			.add(new Renderable(girlBBmp))
			.add(new Transform(600, s2d.getSize().height - girlBBmp.getSize().height, girlBBmp.getSize().width, girlBBmp.getSize().height))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("ClubGirlBBoyC");
				eventBus.publishEvent(event);
			}));

		var girlBBoyBHighlight = world.addEntity("GirlBBoyBHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.club.girlABoyC_highlight.toTile(), parent)))
			.add(girlBBoyB.get(Transform))
			.add(new HoverHighlight());

		currentEntities.push(girlBBoyB);
		currentEntities.push(girlBBoyBHighlight);

		// Boy B
		var boyBbmp = new Bitmap(hxd.Res.club.boyB.toTile(), parent);
		boyBbmp.addShader(wobbleShadder(boyBbmp));
		var boyB = world.addEntity("BoyB")
			.add(new Renderable(boyBbmp))
			.add(new Transform(227, s2d.getSize().height - boyBbmp.getSize().height, boyBbmp.getSize().width, boyBbmp.getSize().height))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("ClubBoyB");
				eventBus.publishEvent(event);
			}));

		var boyBHighlight = world.addEntity("BoyBHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.club.boyB_highlight.toTile(), parent)))
			.add(boyB.get(Transform))
			.add(new HoverHighlight());

		currentEntities.push(boyB);
		currentEntities.push(boyBHighlight);

		// boy A
		var boyABmp = new Bitmap(hxd.Res.club.boyA.toTile(), parent);
		boyABmp.addShader(wobbleShadder(boyABmp));
		var boyA = world.addEntity("BoyA")
			.add(new Renderable(boyABmp))
			.add(new Transform(750, s2d.getSize().height - boyABmp.getSize().height, boyABmp.getSize().width, boyABmp.getSize().height))
			.add(new Clickable(function() {
				var event = new StartDialogueNode("ClubBoyA");
				eventBus.publishEvent(event);
			}));

		var boyAHighlight = world.addEntity("BoyAHighlight")
			.add(new Renderable(new Bitmap(hxd.Res.club.boyA_highlight.toTile(), parent)))
			.add(boyA.get(Transform))
			.add(new HoverHighlight());

		currentEntities.push(boyA);
		currentEntities.push(boyAHighlight);

		spawnSpark(s2d, parent, Const.Levels[1]);
	}

	function loadParty(s2d:Scene, parent:Object, world:World) {
		// BG
		var bgBmp = new Bitmap(hxd.Res.party.party_bg.toTile(), parent);
		var bg = world.addEntity("bg").add(new Renderable(bgBmp));

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

		spawnSpark(s2d, parent, Const.Levels[0]);

		currentEntities.push(bg);
		currentEntities.push(boyA);
		currentEntities.push(boyAHighlight);
		currentEntities.push(girlA);
		currentEntities.push(girlAHighlight);
		currentEntities.push(girlBBoyB);
		currentEntities.push(girlBBoyBHighlight);
		currentEntities.push(boyC);
		currentEntities.push(boyCHighlight);
	}

	function spawnSpark(s2d:Scene, parent:Object, level:String) {
		var sparkTile = hxd.Res.images.spark_128_128.toTile();
		var sparkTiles = [
			for (y in 0...Std.int(sparkTile.height / 128))
				for (x in 0...Std.int(sparkTile.width / 128))
					sparkTile.sub(x * 128, y * 128, 128, 128)
		];
		var path = new Path([new Point(s2d.width, s2d.height - 20), new Point(76, s2d.height - 20)]);

		var timerTile = hxd.Res.timer.toTile();
		var mask = new h2d.Graphics(parent);
		mask.beginFill(0xFF0000, 0.5);
		mask.drawRect(0, 0, timerTile.width, timerTile.height);
		mask.x = 30;
		mask.y = 658;

		var timerBmp = new Bitmap(timerTile, parent);
		timerBmp.addShader(wobbleShadder(timerBmp, .005));
		timerBmp.filter = new Mask(mask);
		var timer = world.addEntity("timer")
			.add(new Renderable(timerBmp))
			.add(new Transform(30, 658, timerBmp.width, timerBmp.height))
			.add(new TimerMask(mask, path));
		var sparkAnim = new h2d.Anim(sparkTiles, parent);

		currentEntities.push(timer);

		var spark = world.addEntity("spark")
			.add(new Renderable(sparkAnim))
			.add(new Transform(0, 0, 128, 128))
			.add(new Spark(path, function() {
				eventBus.publishEvent(new LevelComplete(level));
			}));

		currentEntities.push(spark);
	}

	function removeEntitnes() {
		var e = currentEntities.pop();
		while (e != null) {
			world.removeEntity(e);
			e = currentEntities.pop();
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
		world.addSystem(new TimerMaskSystem());
		world.addSystem(new SparkMover());
		world.addSystem(new CameraController(scene, console));
		world.addSystem(new Renderer(camera));
	}

	public override function update(dt:Float):Void {
		dialogueBox.update(dt);
		world.update(dt);
	}
}
