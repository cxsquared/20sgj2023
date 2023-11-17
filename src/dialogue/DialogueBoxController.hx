package dialogue;

import ecs.utils.MathUtils;
import constant.Const;
import shaders.WobbleShader;
import ui.SelectableOptions;
import constant.GameAction;
import dn.heaps.input.ControllerAccess;
import h2d.Flow;
import assets.Assets;
import hxyarn.dialogue.markup.MarkupParseResult;
import h2d.HtmlText;
import dialogue.event.OptionSelected;
import dialogue.event.NextLine;
import dialogue.event.DialogueComplete;
import dialogue.event.OptionsShown;
import dialogue.event.DialogueHidden;
import dialogue.event.LineShown;
import h2d.Text;
import h2d.ScaleGrid;
import ecs.World;
import h2d.Scene;
import h2d.Object;
import ecs.event.EventBus;

enum abstract DialogueNameLocation(Int) to Int {
	var TopRight;
	var BottomRight;
}

class DialogueBoxController {
	public var isTalking = false;
	public var shouldDistortText = false;
	public var shouldDistortName = false;
	public var currentLevel = 0;

	var eventBus:EventBus;
	var dialogue:DialogueManager;
	var dialogueBackground:ScaleGrid;
	var dialogueName:ScaleGrid;
	var dialogueTextName:HtmlText;
	var dialogueText:HtmlText;
	var options:SelectableOptions;
	var textFlow:Flow;
	var parent:Object;
	var scene:Scene;
	var world:World;
	var currentText:UnicodeString = "";
	var numberOfCharsToShow = 0.0;
	var charsPerSecond = 75.0;
	var textState:DialogueBoxState;
	var lineMarkup:MarkupParseResult;
	var spaceTocontinue:Text;
	var ca:ControllerAccess<GameAction>;
	var nameLocation:DialogueNameLocation;

	public function new(eventBus:EventBus, world:World, parent:Object, ca:ControllerAccess<GameAction>, dialouge:DialogueManager) {
		this.eventBus = eventBus;
		this.world = world;
		this.parent = parent;
		this.scene = parent.getScene();
		this.ca = ca;
		this.dialogue = dialouge;

		scene.addEventListener(function(e) {
			if (e.kind == EPush) {
				clicked = true;
			}
		});

		buildBackground();

		buildNameBackground();

		buildText();

		buildNameText();

		buildContinueText();

		buildOptions();

		eventBus.subscribe(LineShown, this.showLine);
		eventBus.subscribe(OptionsShown, this.showOptions);
		eventBus.subscribe(DialogueComplete, this.dialogueFinished);

		moveTo(4, 4);
		setNameLocation(BottomRight);
	}

	public function getSize() {
		return dialogueBackground.getSize();
	}

	public function moveTo(x:Float, y:Float, nameLocation:DialogueNameLocation = BottomRight) {
		dialogueBackground.setPosition(x, y);
		setNameLocation(nameLocation);
	}

	public function setNameLocation(location:DialogueNameLocation) {
		this.nameLocation = location;

		var dialogueBackgroundSize = dialogueBackground.getSize();

		switch (nameLocation) {
			case TopRight:
				dialogueName.setPosition(dialogueBackground.x + 8, dialogueBackground.y - dialogueName.height * .25);
			case BottomRight:
				dialogueName.setPosition(dialogueBackground.x + 8, dialogueBackground.y + dialogueBackgroundSize.height - dialogueName.height * .75);
		}
	}

	public function showLine(event:LineShown) {
		spaceTocontinue.visible = true;
		if (!textFlow.contains(dialogueText)) {
			textFlow.addChild(dialogueText);
			textFlow.removeChild(options);
		}
		textFlow.addChild(dialogueText);
		isTalking = true;
		numberOfCharsToShow = 0;
		currentText = new UnicodeString(event.line());
		lineMarkup = event.markUpResults;
		dialogueTextName.text = event.characterName();

		if (shouldDistortText) {
			currentText = distortText(currentText);
		}
		dialogueText.text = currentText;
		dialogueText.text = "";

		textState = DialogueBoxState.TypingText;

		dialogueBackground.visible = true;
		var nameKnown = dialogue.getVariable('$$${dialogueTextName.text}NameKnown').asBool();
		if (dialogueTextName.text != "") {
			var name = nameKnown ? dialogue.getVariable('$$${dialogueTextName.text}Name').asString() : "???";
			var color = dialogue.getVariable('$$${dialogueTextName.text}Color').asString();
			if (color == "null")
				color = "#FFFFFF";
			dialogueTextName.text = '<font color="$color">$name</font>';
			if (shouldDistortName) {
				var distortedName = distortText(new UnicodeString(name));
				dialogueTextName.text = '<font color="$color">$distortedName</font>';
			}
			dialogueName.visible = true;
		} else {
			dialogueName.visible = false;
		}
	}

	function distortText(inputString:UnicodeString):UnicodeString {
		var distortedText = "";
		for (c in inputString) {
			if (c >= 4000 || c < 0) {
				c = MathUtils.roll(250);
			}
			var cString = String.fromCharCode(c);
			if (cString == ">" || cString == "<") {
				cString = "?";
			}

			if (MathUtils.roll(40) > Const.distortionChance(Game.current.saveData) - currentLevel) {
				c += MathUtils.roll(100) * MathUtils.randomSign();
				if (c >= 4000 || c < 0) {
					c = MathUtils.roll(250);
				}
				cString = String.fromCharCode(c);
				if (cString == ">" || cString == "<") {
					cString = "?";
				}
			}

			distortedText += cString;
		}

		return distortedText;
	}

	var optionsJustShown = false;

	public function showOptions(event:OptionsShown) {
		optionsJustShown = true;
		spaceTocontinue.visible = false;
		dialogueName.visible = false;

		if (!textFlow.contains(options)) {
			textFlow.addChild(options);
			textFlow.removeChild(dialogueText);
		}
		isTalking = true;

		var width = 0.0;
		var height = 0.0;
		var calculatingText = new Text(Assets.font);
		for (option in event.options) {
			calculatingText.text = option.markup.text;
			width = Math.max(width, calculatingText.calcTextWidth(option.markup.text));
			height = Math.max(height, calculatingText.getSize().height);
		}
		calculatingText.remove();
		width += 32;
		height += 16;

		var o = [];
		for (option in event.options) {
			if (option.enabled) {
				var formatedText = "";
				var pluralAttribute = option.markup.tryGetAttributeWithName("plural");
				if (pluralAttribute != null && pluralAttribute.properties[0].value.integerValue > 0) {
					formatedText = '<font color="#00FF00">*${option.text}*</font>';
				} else {
					formatedText = option.text;
				}

				o.push({
					text: formatedText,
					callback: function() {
						eventBus.publishEvent(new OptionSelected(option.index));
					}
				});
			}
		}

		options.setOptions(o, width, height);

		textState = DialogueBoxState.WaitingForOptionSelection;
	}

	public function dialogueFinished(event:DialogueComplete) {
		dialogueBackground.visible = false;
		dialogueName.visible = false;
		if (textState != DialogueBoxState.WaitingForSkillSelection)
			textState = Hidden;
		// Delay so we don't talk after finish
		haxe.Timer.delay(function() {
			isTalking = false;
			eventBus.publishEvent(new DialogueHidden());
		}, 5);
	}

	var clicked = false;

	public function update(dt:Float) {
		if (textState == Hidden || textState == DialogueBoxState.WaitingForNextLine) {
			clicked = false;
			return;
		}

		if (textState == TypingText) {
			updateText(dt);
		}

		handleContinueText();
		handleOptionSelect();

		clicked = false;
	}

	function handleContinueText() {
		if (isTalking && clickedContinue()) {
			if (textState == TypingText) {
				return;
				// dialogueText.text = applyTextAttributes(currentText);
				// textState = DialogueBoxState.WaitingForContinue;
			} else if (textState == WaitingForContinue) {
				eventBus.publishEvent(new NextLine());
			}
		}
	}

	function handleOptionSelect() {
		if (textState == WaitingForOptionSelection) {
			if (optionsJustShown) {
				optionsJustShown = false;
				return;
			}

			options.update();
		}
	}

	function clickedContinue() {
		return clicked || ca.isPressed(GameAction.Select);
	}

	function updateText(dt:Float) {
		numberOfCharsToShow += charsPerSecond * dt;
		var textLenght = Math.min(currentText.length, Math.floor(numberOfCharsToShow));
		var rawText = currentText.substring(0, Math.floor(textLenght));
		dialogueText.text = applyTextAttributes(rawText);

		if (shouldDistortName && numberOfCharsToShow % 10 > 3) {
			dialogueText.text = distortText(dialogueText.text);
			spaceTocontinue.text = distortText(spaceTocontinue.text);
		}

		if (rawText == currentText) {
			textState = DialogueBoxState.WaitingForContinue;
		}
	}

	function applyTextAttributes(text:String):String {
		var characterOffest = 0;
		var characterAttribute = lineMarkup.tryGetAttributeWithName("character");
		if (characterAttribute != null)
			characterOffest = -characterAttribute.length;

		var htmlTagsByIndex = new Map<Int, String>();

		for (attribute in lineMarkup.attributes) {
			var startTagIndex = attribute.position + characterOffest;
			if (startTagIndex < text.length) {
				var currrentStartTag = "";
				var currentEndTag = "";
				var endTagIndex = Std.int(Math.min(text.length, startTagIndex + attribute.length));
				if (htmlTagsByIndex.exists(startTagIndex))
					currrentStartTag = htmlTagsByIndex.get(startTagIndex);

				if (htmlTagsByIndex.exists(endTagIndex))
					currentEndTag = htmlTagsByIndex.get(endTagIndex);

				// font changes
				if (attribute.name == "font") {
					var openTag = '$currrentStartTag<font';
					var closeTag = '</font>$currentEndTag';
					for (property in attribute.properties) {
						if (property.name == "color") {
							openTag += ' color="' + property.value.stringValue + '"';
						}

						if (property.name == "opacity") {
							openTag += ' opacity="' + property.value.floatValue + '"';
						}
					}
					openTag += '>';
					htmlTagsByIndex.set(startTagIndex, openTag);
					htmlTagsByIndex.set(endTagIndex, closeTag);
				}

				// italics
				if (attribute.name == "i") {
					var openTag = '$currrentStartTag<i>';
					var closeTag = '</i>$currentEndTag';
					htmlTagsByIndex.set(startTagIndex, openTag);
					htmlTagsByIndex.set(endTagIndex, closeTag);
				}

				// italics
				if (attribute.name == "b") {
					var openTag = '$currrentStartTag<b>';
					var closeTag = '</b>$currentEndTag';
					htmlTagsByIndex.set(startTagIndex, openTag);
					htmlTagsByIndex.set(endTagIndex, closeTag);
				}
			}
		}

		var sb = new StringBuf();

		for (i in 0...text.length) {
			var char = text.charAt(i);
			if (htmlTagsByIndex.exists(i)) {
				sb.add(htmlTagsByIndex.get(i));
			}

			sb.add(char);
		}

		if (htmlTagsByIndex.exists(text.length)) {
			sb.add(htmlTagsByIndex.get(text.length));
		}

		return sb.toString();
	}

	function buildBackground() {
		dialogueBackground = new ScaleGrid(hxd.Res.images.TalkBox_16x16.toTile(), 4, 4, parent);
		dialogueBackground.visible = false;
		dialogueBackground.color.a = .85;
		dialogueBackground.width = scene.width - 8;
		dialogueBackground.height = scene.height / 2 - 8;

		var shader = new WobbleShader();
		shader.speed = 5;
		shader.strength = .005;
		shader.frames = 5;
		shader.texture = dialogueBackground.tile.getTexture();
		shader.flowMap = hxd.Res.noise.toTexture();
		dialogueBackground.addShader(shader);
	}

	function buildNameBackground() {
		var dialogueBackgroundSize = dialogueBackground.getSize();

		dialogueName = new ScaleGrid(hxd.Res.images.TalkBox_16x16.toTile(), 4, 4, parent);
		dialogueName.visible = false;
		dialogueName.width = dialogueBackgroundSize.width / 4;
		dialogueName.height = dialogueBackgroundSize.height / 5;
	}

	function buildText() {
		var dialogueBackgroundSize = dialogueBackground.getSize();

		textFlow = new Flow(dialogueBackground);
		textFlow.borderWidth = 8;
		textFlow.borderHeight = 8;
		textFlow.horizontalAlign = FlowAlign.Middle;
		textFlow.verticalAlign = FlowAlign.Middle;
		textFlow.minWidth = Std.int(dialogueBackgroundSize.width);
		textFlow.minHeight = Std.int(dialogueBackgroundSize.height);
		// textFlow.backgroundTile = h2d.Tile.fromColor(0xffffff, 32, 32);

		dialogueText = new HtmlText(Assets.font);
		dialogueText.maxWidth = dialogueBackgroundSize.width - 16;
	}

	function buildNameText() {
		var nameTextFlow = new Flow(dialogueName);
		nameTextFlow.borderWidth = 8;
		nameTextFlow.borderHeight = 8;
		nameTextFlow.horizontalAlign = FlowAlign.Middle;
		nameTextFlow.verticalAlign = FlowAlign.Middle;
		nameTextFlow.minWidth = Std.int(dialogueName.width);
		nameTextFlow.minHeight = Std.int(dialogueName.height);

		dialogueTextName = new HtmlText(Assets.font);
		dialogueTextName.text = "Player";
		dialogueTextName.maxWidth = dialogueName.width;
		nameTextFlow.addChild(dialogueTextName);
	}

	function buildContinueText() {
		spaceTocontinue = new Text(Assets.font, dialogueBackground);
		spaceTocontinue.setScale(.75);
		spaceTocontinue.text = "Click to Continue";
		spaceTocontinue.setPosition(dialogueBackground.getSize().width
			- spaceTocontinue.getSize().width
			- 8,
			dialogueBackground.getSize().height
			- spaceTocontinue.getSize().height
			- 8);
	}

	function buildOptions() {
		var dialogueBackgroundSize = dialogueBackground.getSize();
		options = new SelectableOptions(ca, hxd.Res.images.TalkBox_16x16.toTile());
		options.onSelectCallback = function() {
			textState = DialogueBoxState.WaitingForNextLine;
		};
		options.borderWidth = 8;
		options.borderHeight = 8;
		options.layout = FlowLayout.Vertical;
		options.horizontalAlign = FlowAlign.Middle;
		options.verticalAlign = FlowAlign.Middle;
		options.minWidth = Std.int(dialogueBackgroundSize.width);
		options.minHeight = Std.int(dialogueBackgroundSize.height);
		options.verticalSpacing = 8;
	}

	public function remove() {
		eventBus.unsubscribe(LineShown, this.showLine);
		eventBus.unsubscribe(OptionsShown, this.showOptions);
		eventBus.unsubscribe(DialogueComplete, this.dialogueFinished);
	}
}

enum DialogueBoxState {
	Hidden;
	TypingText;
	WaitingForNextLine;
	WaitingForContinue;
	WaitingForOptionSelection;
	WaitingForSkillSelection;
}
