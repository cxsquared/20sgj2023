package component;

import ecs.component.IComponent;

class Clickable implements IComponent {
	public var onClick:() -> Void;

	public function new(onClick:() -> Void) {
		this.onClick = onClick;
	}

	public function debugText():String {
		return '[Clickable]';
	}

	public function remove() {}
}
