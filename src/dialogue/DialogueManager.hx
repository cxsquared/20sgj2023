package dialogue;

import h2d.Console;
import hxyarn.dialogue.Command;
import hxyarn.dialogue.OptionSet;
import hxyarn.dialogue.Line;
import hxyarn.compiler.Compiler;
import hxyarn.dialogue.StringInfo;
import hxyarn.dialogue.Dialogue;
import hxyarn.dialogue.VariableStorage.MemoryVariableStore;
import hxyarn.dialogue.markup.MarkupParseResult;
import hxyarn.compiler.CompilationJob;
import ecs.event.EventBus;
import dialogue.event.StartNode;
import dialogue.event.DialogueComplete;
import dialogue.event.OptionSelected;
import dialogue.event.OptionsShown;
import dialogue.event.NextLine;
import dialogue.event.LineShown;
import dialogue.event.OptionsShown.OptionChoice;
import dialogue.command.ICommandHandler;

class DialogueManager {
	var storage = new MemoryVariableStore();
	var dialogue:Dialogue;
	var stringTable:Map<String, StringInfo>;
	var lastNodeName:String;
	var runningDialouge:Bool = false;
	var eventBus:EventBus;
	var console:Console;
	var commandHandlers = new Map<String, ICommandHandler>();
	var debug = false;

	public var waitingForOption:Bool = false;

	public function new(eventBus:EventBus, ?console:Console) {
		this.console = console;
		this.eventBus = eventBus;
		dialogue = new Dialogue(storage);

		dialogue.logDebugMessage = this.logDebugMessage;
		dialogue.logErrorMessage = this.logErrorMessage;
		dialogue.lineHandler = this.lineHandler;
		dialogue.optionsHandler = this.optionsHandler;
		dialogue.commandHandler = this.commandHandler;
		dialogue.nodeCompleteHandler = this.nodeCompleteHandler;
		dialogue.nodeStartHandler = this.nodeStartHandler;
		dialogue.dialogueCompleteHandler = this.dialogueCompleteHandler;

		eventBus.subscribe(NextLine, this.nextLine);
		eventBus.subscribe(OptionSelected, this.optionSelected);
		eventBus.subscribe(StartDialogueNode, function(event) {
			this.runNode(event.node);
		});
	}

	public function addCommandHandler(handler:ICommandHandler) {
		if (handler.commandName == null || handler.commandName == "") {
			logErrorMessage("Command handler has no command name");
			return;
		}

		commandHandlers.set(handler.commandName, handler);
	}

	public function getNodeNames(?includesTag = "") {
		var nodeNames = [];
		for (nodeName in dialogue.allNodes) {
			if (includesTag == "") {
				nodeNames.push(nodeName);
				continue;
			}

			var tags = dialogue.getTagsForNode(nodeName);
			if (tags.contains(includesTag)) {
				nodeNames.push(nodeName);
			}
		}
		return nodeNames;
	}

	public function setVariable(name:String, value:Dynamic) {
		storage.setValue(name, value);
	}

	public function getVariable(name:String) {
		return storage.getValue(name);
	}

	public function load(texts:Array<String>, names:Array<String>) {
		var job = CompilationJob.createFromStrings(texts, names, dialogue.library);
		var compiler = Compiler.compile(job);
		stringTable = compiler.stringTable;

		dialogue.addProgram(compiler.program);
	}

	// TODO: Figure out queueing up nodes to run
	public function runNode(nodeName:String) {
		dialogue.setNode(nodeName);
		dialogue.resume();
	}

	public function unload() {
		dialogue.unloadAll();
	}

	public function resume() {
		dialogue.resume();
	}

	public function logDebugMessage(message:String):Void {
		if (console != null && debug) {
			console.log('[Dialouge] $message');
		}
	}

	public function logErrorMessage(message:String):Void {
		if (console != null)
			console.log('[Dialouge] $message', 0xFF0000);
	}

	public function nextLine(event:NextLine) {
		if (dialogue.isActive())
			dialogue.resume();
	}

	public function stop() {
		eventBus.publishEvent(new DialogueComplete(lastNodeName));
		lastNodeName = "";
		waitingForOption = false;
		runningDialouge = false;
		dialogue.stop();
	}

	public function lineHandler(line:Line) {
		var markupResults = getMarkupForLine(line);
		eventBus.publishEvent(new LineShown(markupResults));
	}

	public function optionsHandler(options:OptionSet) {
		var optionChoices = new Array<OptionChoice>();

		for (i => option in options.options) {
			var text = getComposedTextForLine(option.line);
			optionChoices.push({
				text: text,
				index: i,
				enabled: option.enabled,
				markup: getMarkupForLine(option.line)
			});
		}

		eventBus.publishEvent(new OptionsShown(optionChoices));

		waitingForOption = true;
	}

	public function optionSelected(event:OptionSelected) {
		dialogue.setSelectedOption(event.index);
		dialogue.resume();
		waitingForOption = false;
	}

	function getMarkupForLine(line:Line):MarkupParseResult {
		var substitutedText = Dialogue.expandSubstitutions(stringTable[line.id].text, line.substitutions);

		return dialogue.parseMarkup(substitutedText);
	}

	function getComposedTextForLine(line:Line):String {
		return getMarkupForLine(line).text;
	}

	public function commandHandler(command:Command) {
		// TODO normalize to trim whitespaces down to 1 space
		var parts = command.text.split(' ');
		var key = parts.shift();
		if (commandHandlers.exists(key)) {
			commandHandlers.get(key).handleCommand(parts);
			resume();
			return;
		}
	}

	public function nodeCompleteHandler(nodeName:String) {
		lastNodeName = nodeName;
	}

	public function nodeStartHandler(nodeName:String) {
		runningDialouge = true;
	}

	public function dialogueCompleteHandler() {
		runningDialouge = false;
		lastNodeName = "";
		eventBus.publishEvent(new DialogueComplete(lastNodeName));
	}

	public function isActive() {
		return runningDialouge;
	}
}
