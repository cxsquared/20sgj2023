package component;

import ecs.utils.Path;
import ecs.component.IComponent;

class Spark implements IComponent {
	public var path:Path;
	public var currentTime = 0.;

	public function new(path:Path) {
		this.path = path;
	}

	public function debugText():String {
		return "[spark]";
	}

	public function remove() {}
}
