package ecs.component;

import ecs.utils.MathUtils;
import h2d.Console;

class Velocity implements IComponent {
	public var dx:Float;
	public var dy:Float;
	public var friction:Float;
	public var accel = 25;
	public var maxSpeed = 100;

	public function new(?dx:Float = 0, ?dy:Float = 0, ?friction:Float = .95) {
		this.dx = dx;
		this.dy = dy;
		this.friction = friction;
	}

	public function debugText():String {
		var sb = new StringBuf();
		sb.add('[Velocity] dx: ${MathUtils.floatToStringPrecision(dx, 2)}, dy: ${MathUtils.floatToStringPrecision(dy, 2)}');
		sb.add('\n  accel: ${accel}, maxSpeed: ${maxSpeed}, friction: ${friction}');
		return sb.toString();
	}

	public function remove() {}
}
