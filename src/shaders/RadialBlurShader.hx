package shaders;

import hxsl.Shader;

/*
	放射状ブラーエフェクト by あるる（きのもと　結衣） @arlez80
	Radial Blur Effect by Yui Kinomoto

	MIT License
	shader_type canvas_item;

	// 発射中央部
	uniform vec2 blur_center = vec2( 0.5, 0.5 );
	// ブラー強度
	uniform float blur_power : hint_range( 0.0, 1.0 ) = 0.01;
	// サンプリング回数
	uniform int sampling_count : hint_range( 1, 64 ) = 6;

	void fragment( )
	{
	vec2 direction = SCREEN_UV - blur_center;
	vec3 c = vec3( 0.0, 0.0, 0.0 );
	float f = 1.0 / float( sampling_count );
	for( int i=0; i < sampling_count; i++ ) {
		c += texture( SCREEN_TEXTURE, SCREEN_UV - blur_power * direction * float(i) ).rgb * f;
	}
	COLOR.rgb = c;
	}
 */
class RadialBlurShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture:Sampler2D;
		@param var blur_center:Vec2 = vec2(0.5, 0.5);
		@param var blur_power:Float = 0.01; // (0.0, 1.0)
		@param var sampling_count:Int = 6; // (1, 64)
		function fragment() {
			var direction = input.uv - blur_center;
			var c = vec3(0.0, 0.0, 0.0);
			var f = 1.0 / float(sampling_count);
			for (i in 0...sampling_count) {
				c += texture.get(input.uv - blur_power * direction * float(1)).rgb * f;
			}
			pixelColor.rgb = c;
		}
	}
}
