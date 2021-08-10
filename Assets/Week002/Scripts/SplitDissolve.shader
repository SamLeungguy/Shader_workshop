Shader "MyShader/SplitDissolve"
{
    Properties
    {
        _MainTex ("Main Texture1", 2D) = "white" {}
        _MaskTex ("Mask Texture", 2D) = "white" {}

        _Split("Split", Range(0, 1)) = 0.1
        _ParamX("ParamX", Range(0, 1)) = 0
        _ParamY("ParamY", Range(0, 1)) = 0

        _MyTime("Time", Range(0, 100)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off

            //---------------------------
            CGPROGRAM
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

                float3 center : TEXCOORD2;
                //float3 vertex1 : TEXCOORD2;
                //float3 vertex2 : TEXCOORD3;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float2 maskUv : TEXCOORD4;

                float3 wpos : TEXCOORD5;
                float3 originalWorldPos : TEXCOORD6;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _MaskTex;
            float4 _MaskTex_ST;

            float _Split;
            float _ParamX;
            float _ParamY;
            float _MyTime;

            float4x4 MyInverseTranspose_LocalToWorldMatrix;

            v2f vert (appdata v,
                uint vid : SV_VertexID // vertex ID, needs to be uint
                )
            {
                v2f o;
                float4 wpos    = mul(unity_ObjectToWorld, v.vertex);
                float4 wcenter = mul(unity_ObjectToWorld, float4(v.center, 1));

                //float3x3 rotateX = (1, 0, 0, 0, cos)

                o.originalWorldPos = wpos;

                float4x4 m = MyInverseTranspose_LocalToWorldMatrix;
                m = unity_ObjectToWorld;
                float3 wnormal = normalize(mul(m, float4(v.normal, 0)));
                //float3 wnormal = normalize(mul(m, v.normal));


                float mask = 1 - tex2Dlod(_MaskTex, float4(v.uv, 0, 0)).r;

                uint triangleID = vid / 3;
                uint indexID = vid % 3;

                float split = _Split;

                float w = step(mask, split);
                w = smoothstep(split, split + _ParamX, mask);

                float up = float3(0, 1, 0);;
                float3 dir = float3(0, 1, 0);
                dir = wnormal;

                //dir = lerp(dir, wnormal, split);
                // should use a rotation matrix and lerp it
                dir = lerp(up, wnormal, split);

                wpos.xyz = lerp(wpos.xyz, wcenter.xyz, split) + dir * split;
                //wpos.xyz += dir;

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

                //if (abs(i.wpos.y - i.originalWorldPos.y) > 4)
                //{
                //    discard;
                //}

                return col;
            }
            ENDCG
        }
    }
}
