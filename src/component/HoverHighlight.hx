package component;

import ecs.component.IComponent;

class HoverHighlight implements IComponent {
	public function new() {}

	public function debugText():String {
		return "[Hover Highlight]";
	}

	public function remove() {}
}
