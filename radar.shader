Shader "Unlit/radar"
{
    Properties
    {
		
		
    }
    SubShader
    {
		//Opaque
        Tags { "RenderType"="Transparent" }
     
		Blend One Zero
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#define SMOOTH(r,R) (1-smoothstep(R-1,R+1,r))
			#define M_PI 3.1415926535897932384626433832795
		//	#define mod(x,y) (x-y*floor(x/y)) 
			#define RS(a,b,x) (smoothstep(a-1,a+1,x)*(1-smoothstep(b-1,b+1,x)))
			#define MOV(a,b,c,d,t) (float2(a*cos(t)+b*cos(0.1*(t)),c*sin(t)+d*cos(0.1*(t))))

            #include "UnityCG.cginc"

	

            struct appdata
            {
                float4 vertex : POSITION;
               // float2 uv : TEXCOORD0;
            };

            struct v2f
            {
               // float2 uv : TEXCOORD0;
				float4 srcPos:TEXCOORD0;
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.srcPos = ComputeScreenPos(o.vertex);
                return o;
            }

			float3 circle(float2 uv, float2 center, float radius,float width) {
				float r = length(uv - center);
				r = SMOOTH(r - width / 2, radius) - SMOOTH(r + width / 2, radius);
				return float3(r, r, r);
			}

			float circle2(float2 uv, float2 center, float radius, float width,float opening) {
				float2 d = uv - center;
				float r = sqrt(dot(d, d));
				d = normalize(d);

				if (abs(d.y)>opening)
				{
					return SMOOTH(r - width / 2, radius) - SMOOTH(r + width / 2, radius);
				}
				else
					return 0;

			}

			float circle3(float2 uv, float2 center, float radius, float width){
				float2 d = uv - center;
				float r = sqrt(dot(d, d));
				d = normalize(d);
				float theta = 180 * (atan2(d.y,d.x) / M_PI);
				theta = abs(theta);
				return smoothstep(2.0, 2.1, abs(fmod(theta + 2, 45) - 2))*lerp(0.5, 1.0, step(45, abs(fmod(theta, 180) - 90)))*(SMOOTH(r - width / 2, radius) - SMOOTH(r + width / 2, radius));
			}

			float _cross(float2 uv,float2 center,float radius) {
				float2 d = uv - center;
				int x = int(d.x);
				int y = int(d.y);
				float r = sqrt(dot(d, d));
				if ((r < radius) && (x == y || x == -y))
					return 1;
				else return 0;
				
			}

			float triangles(float2 uv,float2 center,float radius) {
				float2 d = uv - center;
				return RS(-8, 0, d.x - radius)*(1 - smoothstep(7 + d.x - radius, 9 + d.x - radius, abs(d.y)))
					+ RS(0, 8.0, d.x + radius)*(1 - smoothstep(7 - d.x - radius, 9 - d.x - radius, abs(d.y)))
					+ RS(-8, 0, d.y - radius)*(1 - smoothstep(7 + d.y - radius, 9 + d.y - radius, abs(d.x)))
					+ RS(0, 8, d.y + radius)*(1 - smoothstep(7 - d.y - radius, 9 - d.y - radius, abs(d.x)));
			}

			float movingLine(float2 uv, float2 center, float radius) {
				float theta0 = 90.0*_Time.y;
				float2 d = uv - center;
				float r = sqrt(dot(d, d));

				if (r<radius)
				{
					float2 p = radius * float2(cos(theta0*M_PI / 180.0), -sin(theta0*M_PI / 180.0));
					float l = length(d - p * clamp(dot(d, p) / dot(p, p), 0, 1));
					d = normalize(d);

					float theta = fmod(180 * atan2(d.y, d.x) / M_PI + theta0, 360);
					float gradient = clamp(1 - theta / 90, 0, 1);
					return 0.5*gradient;
				}
				else
					return 0;

			}

			float bip1(float2 uv, float2 center) {
				return SMOOTH(length(uv - center), 3);
			}

			float bip2(float2 uv, float2 center) {
				float r = length(uv - center);

				float R = 8.0 + fmod(87 * _Time.y, 80);

				return (0.5 - 0.5*cos(30 * _Time.y))*SMOOTH(r, 5) + SMOOTH(6, r) - SMOOTH(8, r) + smoothstep(max(8, R - 20), R, r) - SMOOTH(R, r);

			}


            fixed4 frag (v2f i) : SV_Target
            {
				float2 fragCoord = (i.srcPos.xy / i.srcPos.w)*_ScreenParams.xy;
				float3 finalColor;
				float2 center = _ScreenParams.xy / 2;
				float temp = 0.3*_cross(fragCoord, center, 240.0);
				finalColor = float3(temp,temp,temp);
				finalColor += (circle(fragCoord, center, 100, 1) + circle(fragCoord, center, 165, 1))*float3(0.74, 0.95, 1);
				finalColor += circle(fragCoord, center, 240, 2);

				finalColor += circle3(fragCoord, center, 313, 4)*float3(0.74, 0.95, 1);

				finalColor += triangles(fragCoord, center, 315 + 30 * sin(_Time.y))*float3(0.87, 0.98, 1);

				//finalColor += movingLine(fragCoord, center, 240)*float3(0.35, 0.76, 0.83);

				finalColor += circle(fragCoord, center, 10, 1)*float3(0.35, 0.76, 0.83);

				finalColor += 0.7*circle2(fragCoord, center, 262, 1, 0.5 + 0.2*cos(_Time.y))*float3(0.35, 0.76, 0.83);

				if (length(fragCoord-center)<240)
				{
					float2 p = 130 * MOV(1.3, 1.0, 1.0, 1.4, 3 + 0.1*_Time.y);
					finalColor += bip1(fragCoord, center + p)*float3(1, 1, 1);
					p = 130 * MOV(0.9, -1.1, 1.7, 0.8, -2 + sin(0.1*_Time.y) + 0.15*_Time.y);
					finalColor += bip1(fragCoord, center + p)*float3(1, 1, 1);
					p = 50 * MOV(1.54, 1.7, 1.37, 1.8, sin(0.1*_Time.y + 7) + 0.2*_Time.y);
					finalColor += bip2(fragCoord, center + p)*float3(1, 0.38, 0.227);
				}

				float tt = movingLine(fragCoord, center, 240);
				finalColor +=tt*float3(0.35, 0.76, 0.83);
				
				

                return fixed4(finalColor.rgb,tt);				
            }
            ENDCG
        }
    }
}
