Shader "MyShader/Dissolve"
{
    Properties
    {
        [Header(Texture)]
        texA    ("texA", 2D) = "white" {}
        texB    ("texB", 2D) = "white" {}
        texMask ("texMask", 2D) = "white" {}

        [Header(Parameter)]
        dissovle         ("dissovle",        Range(0, 1.0)) = 0.5
        edgeWdith        ("edgeWdith",       Range(0, 0.999)) = 0.1
        edgeSoftness     ("edgeSoftness",    Range(0, 1.0)) = 0.1
        [HDR]edgeColor   ("edgeColor",       Color)         = (1, 1, 1, 1)
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
            };

            // Dissolve
            float dissovle;
            float edgeWdith;
            float edgeSoftness;
            float4 edgeColor;

            sampler2D texA;
            sampler2D texB;
            sampler2D texMask;
            float4 texMask_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            float extractDomain(float var, float min, float max)
            {
                if ( var < min )
                {
                    return 0;
                }
                if ( var > max )
                {
                    return 0;
                }
                return var;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 a = tex2D(texA, i.uv);
                float4 b = tex2D(texB, i.uv);

                float4 dissovleMask = tex2D(texMask, i.uv * texMask_ST.xy).r;
                dissovleMask = dissovleMask * 0.999;

                // when dissove increase, more pixels go to -ve
                float dissolveWeighting = dissovleMask - dissovle; // => -1 ~ 1
                //clip(dissolveWeighting);

                // all the -ve dissolveWeighting to 1 (change to texB)
                float transitWeighting = smoothstep(0.1, 0, dissolveWeighting);     // 0~0.1 => 1~0
                //float4 o = a * (1 - transitWeighting) + b * transitWeighting;
                float4 o = lerp(a, b, transitWeighting);
                
                // -ve dissolveWeighting to 0 (changed to texB),  [0, 0.1] for dissolveWeighting become edge,
                // (0.1, 1] for dissolveWeighting (remain texA)
                float edgeWidthWeighting = smoothstep(0, 0.1, dissolveWeighting);   // 0~0.1 => 0~1
                edgeWidthWeighting = extractDomain(edgeWidthWeighting, 0, edgeWdith);
                float4 tempEdgeColor = edgeWidthWeighting * edgeColor;

                // softness (give up, gg)
                float4 aa = float4(edgeSoftness, edgeSoftness, edgeSoftness, 1.0);
                float4 finalEdgeColor = 2 * aa * tempEdgeColor;                     // https://en.wikipedia.org/wiki/Blend_modes
                //float4 finalEdgeColor = 1 - 2 * (1 - aa) * (1 - tempEdgeColor);

                return o + finalEdgeColor;
            }
            ENDCG
        }
    }
}
