package shaders;

class WobbleShader extends hxsl.Shader {
	/*

		https://godotshaders.com/shader/wobbly-effect-hand-painted-animation/
		uniform sampler2D flowMap; //Displacement map
		uniform float strength;    //Force of the effect
		uniform float speed;       //Speed of the effect
		uniform int frames : hint_range(1, 10); //Frames of the effect

		//Returns a value between 0 and 1 depending of the frames -> exemple: frames = 4, frame 1 = 0.25
		float clock(float time){
			float fframes = float(frames);
			return floor(mod(time * speed, fframes)) / fframes;
		}

		void fragment(){
			float c = clock(TIME); //Get clock frame
			vec4 offset = texture(flowMap, vec2(UV.x + c, UV.y + c)) * strength; //Get offset 
			//COLOR = texture(TEXTURE, vec2(UV.x,UV.y) + normal.xy); //Apply offset
			COLOR = texture(TEXTURE, vec2(UV.x,UV.y) + offset.xy - vec2(0.5,0.5)*strength); //We need to remove the displacement 
		}
	 */
	static var SRC = {
		@:import h3d.shader.Base2d;
		@param var texture:Sampler2D;
		@param var flowMap:Sampler2D;
		@param var speed:Float;
		@param var strength:Float;
		@param var frames:Int;
		function clock():Float {
			var fframes = float(frames);
			return floor(mod(time * speed, fframes)) / fframes;
		}
		function fragment() {
			var c = clock();
			var offset = flowMap.get(vec2(calculatedUV.x + c, calculatedUV.y + c)) * strength;
			pixelColor = texture.get(calculatedUV + offset.xy - vec2(0.5, 0.5) * strength);
		}
	}
}
