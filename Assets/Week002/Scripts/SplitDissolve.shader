Shader "MyShader/SplitDissolve"
{
    Properties
    {
        _MainTex ("Main Texture1", 2D) = "white" {}
        _MaskTex ("Mask Texture", 2D) = "white" {}

        _Split("Split", Range(0, 1)) = 0.1
        _ParamX("ParamX", Range(0, 1)) = 0
        _ParamY("ParamY", Range(0, 1)) = 0

        _Duration("Duration", Range(0, 10)) = 1
        _Delay("Delay", Range(0, 10)) = 0

        _Offset("Offset", float) = 1
		_Scale("Scale", float) = 1
		_Spread("Spread", float) = 0.15

        _MyTime("Time", Range(0, 10)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
		Cull Off

        Pass
        {
            //Cull Off

            //---------------------------
            CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
//          #pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma target 4.5

            #include "UnityCG.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;

                float4 center : TEXCOORD1;
                float2 newUv : TEXCOORD2;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float2 maskUv : TEXCOORD4;

                float3 wpos : TEXCOORD5;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            float _Split;
            float _ParamX;
            float _ParamY;
            float _MyTime;

            float _Duration;
            float _Delay;
			float _Offset;
			float _Scale;
            float _Spread;

            float4x4 MyInverseTranspose_LocalToWorldMatrix;
            float4x4 MyRotateYMatrix;

            float4 getMatrixTranslate(float4x4 m)
            {
                return m._m03_m13_m23_m33;
            }

            v2f vert (appdata v,
                uint vid : SV_VertexID // vertex ID, needs to be uint
                )
            {
                v2f o;

                float mask = 1 - tex2Dlod(_MaskTex, float4(v.newUv, 0, 0)).r;
                float rdm = v.center.w;
                //rdm = mask;

                float4x4 m = MyInverseTranspose_LocalToWorldMatrix;
                m = unity_ObjectToWorld;

                float3 wnormal = normalize(mul(m, float4(v.normal, 0)));

                float intensity = saturate((rdm - 1 + _MyTime - _Delay) / _Duration);

                float scale = saturate(intensity * _Scale);
                v.vertex.xyz = lerp(v.vertex.xyz, v.center.xyz, scale);

                float4 wpos           = mul(unity_ObjectToWorld, v.vertex);
				float4 objectWorldPos = getMatrixTranslate(unity_ObjectToWorld);
                
                float  y  = intensity * _Offset;
				float2 xz = wpos.xz - objectWorldPos.xz;
				
				wpos.y  += y * y;
				wpos.xz += xz * (intensity) * _Spread;

                // v2f -------------------
                o.vertex = mul(UNITY_MATRIX_VP, wpos);
                o.wpos = wpos;
                o.uv = v.uv;
                o.maskUv = TRANSFORM_TEX(v.uv, _MaskTex);
                o.normal = v.normal;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }
    }
}
