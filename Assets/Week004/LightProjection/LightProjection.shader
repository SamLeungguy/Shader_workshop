Shader "MyShader/LightProjection"
{
    Properties
    { 
        _MainTex("Texture", 2D) = "white" {}
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        //ZTest Always
		//ZWrite Off
        //
		//Blend SrcAlpha OneMinusSrcAlpha


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../../MyCommon/MyCommon.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
            };
            
            Varyings vert(Attributes i)
            {
                Varyings o;

                o.positionHCS = i.positionOS;
                return o;
            }

			MY_TEXTURE2D(_MainTex)

            half4 frag(Varyings i) : SV_Target
            {
                static const float epsilon = 0.0001f;

                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;
                
                // Sample the depth from the Camera depth texture.
                #if UNITY_REVERSED_Z
                    float depth = SampleSceneDepth(screenUV);
                #else
                    // Adjust Z to match NDC for OpenGL ([-1, 1])
                    float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
                #endif

                return float4(depth * 100, depth * 100, depth * 100, 1);
            }
            ENDHLSL
        }
    }
}