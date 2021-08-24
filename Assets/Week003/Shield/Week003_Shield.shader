// This Unity shader reconstructs the world space positions for pixels using a depth
// texture and screen space UV coordinates. The shader draws a checkerboard pattern
// on a mesh to visualize the positions.
Shader "MyShader/Week003_Shield"
{
    Properties
    { 
        _EdgeTex           ("Edge Texture", 2D)            = "white" {}
        _EdgeIntensity     ("Edge Intensity", float)       = 2.0
        _EdgeTimeScale     ("Edge Time Scale", float)      = 2.0
        _EdgePosScale      ("Edge Position Scale", float)  = 80.0
        _EdgeColor         ("EdgeColor", Color)            = (0,0,0,0)
        _EdgeWidth         ("EdgeWidth", Range(0,1))       = 20
        _EdgeSoftness      ("EdgeSoftness", Range(0,1))    = 0.2

        _PulseTex      ("Pulse Texture", 2D)                      = "white" {}
        _PulseIntensity("Pulse Intensity", float)                 = 3.0
        _PulseTimeScale("Pulse Time Scale", float)                = 2.0
        _PulsePosScale ("Pulse Position Scale", float)            = 50.0
        _PulseTexOffsetScale("Pulse Texture Offset Scale", float) = 1.5

        _OutlineTex         ("Outline Texture", 2D) = "white" {}
        _OutlineIntensity   ("Outline Intensity", float) = 10.0
        _OutlineExponent    ("Outline Falloff Exponent", float) = 6.0

        _IntersectColor     ("IntersectColor", Color)                = (1,0,0,1)
        _IntersectIntensity ("Intersection Intensity", float)        = 10.0
        _IntersectExponent  ("Intersection Falloff Exponent", float) = 6.0
        _Intersect          ("Intersection Intensity", Range(0,1))   = 1.0

        _BaseColor     ("BaseColor", Color)         = (1,0,0,1)


        _MyTime         ("My time", Range(0,400))      = 0
       	_PivotX("PivotX", range(0, 1))                 = 0.5
		_PivotY("PivotY", range(0, 1))                 = 0.5
        _DepthOffset("DepthOffset", range(0, 10))      = 1
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags { "RenderType" = "Opaque" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline" }

        Cull Off
        Blend SrcAlpha One

        Pass
        {

            HLSLPROGRAM
            // This line defines the name of the vertex shader.
            #pragma vertex vert
            // This line defines the name of the fragment shader.
            #pragma fragment frag

            //#include "UnityCG.cginc"

            // The Core.hlsl file contains definitions of frequently used HLSL
            // macros and functions, and also contains #include references to other
            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // The DeclareDepthTexture.hlsl file contains utilities for sampling the
            // Camera depth texture.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            // This example uses the Attributes structure as an input structure in
            // the vertex shader.
            struct Attributes
            {
                // The positionOS variable contains the vertex positions in object
                // space.
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 vertexObjPos : TEXCOORD1;
                float3 w_pos        : TEXCOORD2;

            };

            // eddge
            sampler2D _EdgeTex;
            float4 _EdgeTex_ST;
            float _EdgeIntensity;
            float _EdgeTimeScale;
            float _EdgePosScale;
            float4 _EdgeColor; 
            float _EdgeWidth;    
            float _EdgeSoftness; 
            // pulse
            sampler2D _PulseTex;
            float4 _PulseTex_ST;
            float _PulseIntensity;
            float _PulseTimeScale;
            float _PulsePosScale;
            float _PulseTexOffsetScale;

            sampler2D _OutlineTex;
            float4 _OutlineTex_ST;
            float _OutlineIntensity;
            float _OutlineExponent;

            float4 _IntersectColor;
            float _IntersectIntensity;
            float _IntersectExponent;
            float _Intersect;

            float4 _BaseColor;


            float _MyTime;
            float _PivotX;
            float _PivotY;
            float _DepthOffset;
            // The vertex shader definition with properties defined in the Varyings
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes i)
            {
                // Declaring the output object (o) with the Varyings struct.
                Varyings o;
                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous clip space.
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                // Returning the output.
                o.vertexObjPos = i.positionOS;

                o.uv = TRANSFORM_TEX(i.uv, _PulseTex);

                o.w_pos = TransformObjectToWorld(i.positionOS.xyz);
                return o;
            }

            // The fragment shader definition.
            // The Varyings input structure contains interpolated values from the
            // vertex shader. The fragment shader uses the `positionHCS` property
            // from the `Varyings` struct to get locations of pixels.
            half4 frag(Varyings i) : SV_Target
            {
                static const float epsilon = 0.0001f;

                float2 screenUV = i.positionHCS.xy / _ScaledScreenParams.xy;
                
                // Sample the depth from the Camera depth texture.
                #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(screenUV);
                #else
                    // Adjust Z to match NDC for OpenGL ([-1, 1])
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(screenUV));
                #endif

                // Reconstruct the world space positions.
                float3 worldPos = ComputeWorldSpacePosition(screenUV, depth, UNITY_MATRIX_I_VP);

                float3 positionVS0 = ComputeViewSpacePosition(screenUV, depth, UNITY_MATRIX_I_P);
				float3 positionVS1 = ComputeViewSpacePosition(screenUV, i.positionHCS.z, UNITY_MATRIX_I_P);

				float d = saturate(smoothstep(_Intersect, 0, positionVS0.z - positionVS1.z));
                float4 edgeTerm = _EdgeColor * d;
                float4 o = _BaseColor + edgeTerm;


				o.a = 1;
                return o;




				return float4(_BaseColor.rgb + edgeTerm.rgb, 1);

                float diff = saturate(distance(worldPos, i.w_pos));
                float w = 1 - smoothstep(0, _EdgeSoftness, abs(diff - _EdgeWidth));

                float4 tex = tex2D(_EdgeTex, i.uv);

                //_IntersectColor.a *= w;
                //float4 o = tex + _IntersectColor;
                o.a *= w;
                return o;
            }
            ENDHLSL
        }
    }
}