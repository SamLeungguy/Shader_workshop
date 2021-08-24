Shader "MyShader/Week003_WorldScanner"
{
    Properties
    { 
        _MainTex("Texture", 2D) = "white" {}
		[Enum(Week003_WorldScanner_UvMode)]
		_UvMode("UvMode", Int) = 0

		_Color ("Color", Color) = (1,1,1,1)
		_Radius("Radius", Range(0, 300)) = 10
		_EdgeWidth("Edge Width", Range(0,100)) = 5
		_EdgeSoftness("Edge Softness", Range(0,1)) = 0.01
		_ScannerCenter ("ScannerCenter", Vector) = (0,0,0,0)
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        ZTest Always
		ZWrite Off

		Blend SrcAlpha OneMinusSrcAlpha


        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //#include "UnityCG.cginc"

            // The Core.hlsl file contains definitions of frequently used HLSL
            // macros and functions, and also contains #include references to other
            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // The DeclareDepthTexture.hlsl file contains utilities for sampling the
            // Camera depth texture.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../../MyCommon/MyCommon.hlsl"

            // This example uses the Attributes structure as an input structure in
            // the vertex shader.
            struct Attributes
            {
                // The positionOS variable contains the vertex positions in object
                // space.
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
            };
            
            


            // The vertex shader definition with properties defined in the Varyings
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes i)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings o;
                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous clip space.
                //o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);

                o.positionHCS = i.positionOS;
                return o;
            }

            float4 _Color;
			float4 _ScannerCenter;
			float _Radius;
			float _EdgeWidth;
			float _EdgeSoftness;
			int _UvMode;

			MY_TEXTURE2D(_MainTex)

            // The fragment shader definition.
            // The Varyings input structure contains interpolated values from the
            // vertex shader. The fragment shader uses the `positionHCS` property
            // from the `Varyings` struct to get locations of pixels.
            half4 frag(Varyings i) : SV_Target
            {
                static const float epsilon = 0.0001f;

                // To calculate the UV coordinates for sampling the depth buffer,
                // divide the pixel location by the render target resolution
                // _ScaledScreenParams.
                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;
                
                // Sample the depth from the Camera depth texture.
                #if UNITY_REVERSED_Z
                    float depth = SampleSceneDepth(screenUV);
                #else
                    // Adjust Z to match NDC for OpenGL ([-1, 1])
                    float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
                #endif

                //return 1;

                //return float4(depth * 100, depth * 100, depth * 100, 1);

                float3 worldPos = ComputeWorldSpacePosition(screenUV, depth, UNITY_MATRIX_I_VP);

                float3 dir = worldPos - _ScannerCenter.xyz;

                float dist = length(dir);

                float inner = _Radius;
                float outter = _Radius + _EdgeWidth;
                float2 uv = float2(my_invLerp(inner, outter, dist), 0);

                if (_UvMode == 2) {
					uv.y = atan2(dir.z, dir.x) / (2 * PI);
				}

				float4 tex = MY_SAMPLE_TEXTURE2D(_MainTex, uv);

                uv.x = saturate(uv.x);

                float edge = 1 - abs(uv.x * 2 - 1);
                

                //float edge = saturate(1 - abs(uv.x * 2 - 1));

                float alpha = smoothstep(0, _EdgeSoftness, edge);


                tex.a = alpha;

                float4 o = _Color * tex;
                o.a *= alpha;
                return o;
            }
            ENDHLSL
        }
    }
}