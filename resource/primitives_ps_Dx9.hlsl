// pixel shader

float4 iResolution;

float rectangle(in float2 uv, in float2 size2, in float2 off)
{
	float2 d = step(abs(uv - off) - size2, float2(0.0, 0.0));
	return d.x * d.y;
}
float quad(in float2 uv, float size1, in float2 off)
{
	float2 d = step(abs(uv - off) - size1, float2(0.0, 0.0));
	return d.x * d.y;
}
float circle(in float2 uv, float radius, in float2 off)
{
	float2 d = off - uv;
	return step(dot(d, d), radius * radius);
}
float line_(float2 uv, float2 p0, float2 p1, float pointSize) {
	float2 line_ = p1 - p0;
	float2 dir = uv - p0;
		
	pointSize *= pointSize;
		
	float h = clamp(dot(dir, line_) / dot(line_, line_), 0.0, 1.0);
	dir -= line_ * h;
		
	return step(dot(dir, dir) - pointSize, pointSize);
}

#define PI 3.14159265359
#define TWO_PI 6.28318530718
float polygonViaPolar(in float2 uv, float size1, in float2 off, in int N)
{
	uv = off - uv;
	float a = atan2( uv.x,uv.y ) + PI;
	float r = TWO_PI / float(N);
	float d = cos(floor(0.5 + a / r) * r - a) * length(uv);
	return smoothstep( 0.41, 0.4, d / size1 );
}
float triangleViaPolar(in float2 uv, float size1, in float2 off)
{
	return polygonViaPolar( uv, size1, off, 3 );
}
float hexagonViaPolar(in float2 uv, float size1, in float2 off)
{
	return polygonViaPolar( uv, size1, off, 6 );
}

float triangleViaVertsAux_(float2 p1, float2 p2, float2 p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}
float3 triangleViaVerts(float3 color, float3 background, float2 vertices[3], float2 uv)
{
    bool b1 = triangleViaVertsAux_(uv, vertices[0], vertices[1]) < 0.0f;
    bool b2 = triangleViaVertsAux_(uv, vertices[1], vertices[2]) < 0.0f;
    bool b3 = triangleViaVertsAux_(uv, vertices[2], vertices[0]) < 0.0f;
    
    if((b1 == b2) && (b2 == b3))return color;
    return background;
}

float4 main(in float2 position : VPOS) : COLOR {
	float4 fragColor;
	float2 fragCoord = position.xy;

	// Normalized pixel coordinates (from 0 to 1)
	float2 uv = fragCoord / iResolution.yy;
	uv.y = 1 - uv.y; // from GLSL to HLSL

	float3 col = float3(1.0, 1.0, 1.0);
	float shape = 0;
	shape += rectangle(uv, float2(0.2, 0.1), float2(0.25, 0.25));
	shape += quad(uv, 0.1, float2(0.5, 0.5));
	shape += circle(uv, 0.1, float2(0.7, 0.7));
	shape += line_(uv, float2(1.0, 0.3), float2(1.2, 0.2), 0.001);

	shape += triangleViaPolar(uv, 0.2, float2(0.9, 0.9));
	shape += hexagonViaPolar(uv, 0.1, float2(0.2, 0.9));

	float3 background = float3(0.0, 0.0, 0.0);
	float x_ = 0.6, y_ = 0.2;
	float2 VERTS[] = {
			float2(x_ + 0.5, y_ + 0.75)
			, float2(x_ + 0.3, y_ + 0.25)
			, float2(x_ + 0.7, y_ + 0.25)
		};
	shape += triangleViaVerts( float3(1.0, 1.0, 1.0), background, VERTS, uv );

	// Output to screen
	fragColor = float4(col * shape, 1.0);

	return fragColor;
}
