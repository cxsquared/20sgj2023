package component;

import ecs.component.IComponent;
import h2d.Console;

class Player implements IComponent {
	public function new() {}

	public function remove() {}

	public function debugText():String {
		return '[Player]';
	}
}
