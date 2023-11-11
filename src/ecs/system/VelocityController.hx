package ecs.system;

import ecs.component.Velocity;
import ecs.component.Transform;

class VelocityController implements IPerEntitySystem {
	public function new() {}

	public function update(entity:Entity, dt:Float) {
		var t = entity.get(Transform);
		var v = entity.get(Velocity);

		v.dx = hxd.Math.clamp(v.dx * v.friction, -v.maxSpeed, v.maxSpeed);
		v.dy = hxd.Math.clamp(v.dy * v.friction, -v.maxSpeed, v.maxSpeed);

		t.x += v.dx * dt;
		t.y += v.dy * dt;
	}

	public var forComponents:Array<Class<Dynamic>> = [Transform, Velocity];
}
