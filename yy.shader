Shader "Unlit/juxing"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}	   
		_Width("宽高比",float)=2
		[HideInInspector]
		_Hight("hight",float)=1
		_Radius("Radius",Range(0,0.5)) = 0.5

	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 100

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;

					float4 vertex : SV_POSITION;
				};

				sampler2D _MainTex;
				float4 _MainTex_ST;
				float _Radius;
				float _Width;
				float _Hight;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);

					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{									
					fixed4 col;
					if ((i.uv.x*_Width>=_Radius && i.uv.x*_Width<=(_Width-_Radius)) || (i.uv.y*_Hight >= _Radius && i.uv.y*_Hight <= (_Hight - _Radius)))
					{
						col = tex2D(_MainTex, i.uv);
					}
					else {
						float dis1 = distance(float2(_Radius, _Radius), float2(i.uv.x*_Width, i.uv.y*_Hight));
						float dis2 = distance(float2(_Radius, _Hight - _Radius), float2(i.uv.x*_Width, i.uv.y*_Hight));
						float dis3 = distance(float2(_Width - _Radius, _Hight - _Radius), float2(i.uv.x*_Width, i.uv.y*_Hight));
						float dis4 = distance(float2(_Width - _Radius, _Radius), float2(i.uv.x*_Width, i.uv.y*_Hight));

						if (dis1<_Radius || dis2 < _Radius || dis3 < _Radius || dis4 < _Radius)
						{
							col = tex2D(_MainTex, i.uv);
						}
						else {
							discard;
						}
					}						
					return col;
				}
				ENDCG
			}
		}
}
