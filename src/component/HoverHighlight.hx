package component;

import h2d.Scene;
import h2d.Graphics;
import ecs.component.IComponent;

class HoverHighlight implements IComponent {
	public function new() {
	}

	public function debugText():String {
		return "[Hover Highlight]";
	}

	public function remove() {}
}
