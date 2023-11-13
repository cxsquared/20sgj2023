package component;

import ecs.utils.Path;
import ecs.component.IComponent;

class Spark implements IComponent {
	public var path:Path;
	public var currentTime = 0.;
	public var onComplete:() -> Void;
	public var isFinished:Bool = false;

	public function new(path:Path, onComplete:() -> Void) {
		this.path = path;
		this.onComplete = onComplete;
	}

	public function debugText():String {
		return "[spark]";
	}

	public function remove() {}
}
