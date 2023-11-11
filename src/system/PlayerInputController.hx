package system;

import constant.GameAction;
import dn.heaps.input.ControllerAccess;
import ecs.Entity;
import ecs.system.IPerEntitySystem;
import ecs.component.Velocity;
import ecs.component.Transform;
import component.Player;

class PlayerInputController implements IPerEntitySystem {
	public var forComponents:Array<Class<Dynamic>> = [Player, Velocity, Transform];

	public var ca:ControllerAccess<GameAction>;

	public function new(ca:ControllerAccess<GameAction>) {
		this.ca = ca;
	}

	public function update(entity:Entity, dt:Float) {
		var v = entity.get(Velocity);

		var controllerX = ca.getAnalogValue(GameAction.MoveX);
		var controllerY = ca.getAnalogValue(GameAction.MoveY);

		updatePlayerInput(controllerX, controllerY, v);
	}

	function updatePlayerInput(inputX:Float, inputY:Float, v:Velocity):Bool {
		var moving = false;
		if (inputX != 0) {
			v.dx += v.accel * inputX;
			moving = true;
		}
		if (inputY != 0) {
			v.dy += v.accel * inputY;
			moving = true;
		}

		return moving;
	}
}
