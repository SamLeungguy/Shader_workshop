Shader "MyShader/Dissolve2"
{
    Properties
    {
        [Header(Texture)]
        _MainTex1    ("Main Texure1", 2D) = "white" {}
        _MainTex2    ("Main Texure2", 2D) = "white" {}
        _MaskTex     ("Mask Texture", 2D) = "white" {}

        [Header(Parameter)]
        _Dissolve("Dissovle", Range(0, 1)) = 0.5
        _Mode    ("Mode [0:Normal] [1:Radial] [2:Rhombus]", Int) = 1

		_PivotX("PivotX", range(0, 1)) = 0.5
		_PivotY("PivotY", range(0, 1)) = 0.5

        _EdgeWidth       ("EdgeWdith",       Range(0, 1)) = 0.1
        _EdgeSoftness    ("EdgeSoftness",    Range(0, 1)) = 0.1
        [HDR]_EdgeColor  ("EdgeColor",       Color)       = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 maskUv : TEXCOORD1;
            };

            // Dissolve
            sampler2D _MainTex1;
			sampler2D _MainTex2;
			sampler2D _MaskTex;
			float4    _MaskTex_ST;

			float _Dissolve;
			float _PivotX;
			float _PivotY;
			int _Mode;

			float _EdgeWidth;
			float _EdgeSoftness;
			float4 _EdgeColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.maskUv = TRANSFORM_TEX(v.uv, _MaskTex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                const static float epsilon = 1E-4;
                float4 tex1 = tex2D(_MainTex1, i.uv);
                float4 tex2 = tex2D(_MainTex2, i.uv);

                float hardEdge = _EdgeWidth / 2;
                float softEdge = hardEdge + _EdgeSoftness + epsilon;

                if (_Mode == 1)     // circle
                {
                    float2 pos = i.uv - float2(_PivotX, _PivotY);
                    float value = length(pos);
                    _Dissolve = saturate(_Dissolve / max(value, epsilon));
                    //return float4(value, value, value, 1);
                }
                else if (_Mode == 2)        // rhombus
                {   
                    float2 pos = i.uv - float2(_PivotX, _PivotY);
                    float value = abs(pos.x) + abs(pos.y);
                    _Dissolve = saturate(_Dissolve / max(value, epsilon));
                }

                float dissolve = lerp(-softEdge, 1 + softEdge, _Dissolve);

                float mask = 1 - tex2D(_MaskTex, i.maskUv).r;
                float4 o = lerp(tex1, tex2, step(mask, dissolve));

                if (_EdgeWidth || _EdgeSoftness)
                {
                    float edge = abs(mask - dissolve);
                    float edgeWeighting = smoothstep(hardEdge, softEdge, edge);
                    o = lerp(_EdgeColor, o, (edgeWeighting)); 
                    //return float4(edge, edge, edge, 1);
                }
                return o;
            }
            ENDCG
        }
    }
}
