package ecs.utils;

import h2d.col.Point;

class Path {
	var nodes:Array<Point>;
	var time:Float;
	var perOfDistance:Array<Float>;
	var totalLength:Float;
	var distanceBetween:Array<Float>;

	public function new(nodes:Array<Point>, time = 20.0) {
		this.nodes = nodes;
		this.time = time;

		totalLength = 0.;
		distanceBetween = [];
		if (nodes.length < 2)
			throw 'nodes must be longer than 1';

		for (i in 0...nodes.length - 1) {
			var a = nodes[i];
			var b = nodes[i + 1];
			var distance = a.distance(b);
			totalLength += distance;
			distanceBetween.push(distance);
		}

		perOfDistance = [];
		perOfDistance.push(0);
		var perTotal = 0.;
		for (d in distanceBetween) {
			perTotal += d / totalLength;
			perOfDistance.push(perTotal);
		}
	}

	public function getPointAtTime(currentTime:Float):Point {
		if (currentTime == 0)
			return nodes[0];

		if (currentTime >= time)
			return nodes[nodes.length - 1];

		var td = MathUtils.normalizeToOne(currentTime, 0., time);
		var startIndex = 0;
		for (i => d in perOfDistance) {
			if (td < d)
				break;

			startIndex = i;
		}

		var nodeA = nodes[startIndex];
		var nodeB = nodes[startIndex + 1];

		var minD = perOfDistance[startIndex];
		var maxD = perOfDistance[startIndex + 1];

		var dd = MathUtils.normalizeToOne(td, minD, maxD);

		return new Point(hxd.Math.lerp(nodeA.x, nodeB.x, dd), hxd.Math.lerp(nodeA.y, nodeB.y, dd));
	}
}
