// This Unity shader reconstructs the world space positions for pixels using a depth
// texture and screen space UV coordinates. The shader draws a checkerboard pattern
// on a mesh to visualize the positions.
Shader "MyShader/OverwatchShield"
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

            float4 _BaseColor;


            float _MyTime;
            float _PivotX;
            float _PivotY;
            float _DepthOffset;
            // The vertex shader definition with properties defined in the Varyings
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes IN)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings OUT;
                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous clip space.
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // Returning the output.
                OUT.vertexObjPos = IN.positionOS;

                OUT.uv = TRANSFORM_TEX(IN.uv, _PulseTex);

                OUT.w_pos = TransformObjectToWorld(IN.positionOS.xyz);
                return OUT;
            }

            // The fragment shader definition.
            // The Varyings input structure contains interpolated values from the
            // vertex shader. The fragment shader uses the `positionHCS` property
            // from the `Varyings` struct to get locations of pixels.
            half4 frag(Varyings IN) : SV_Target
            {
                static const float epsilon = 0.0001f;

                float2 UV = IN.positionHCS.xy / _ScaledScreenParams.xy;
                
                // Sample the depth from the Camera depth texture.
                #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(UV);
                #else
                    // Adjust Z to match NDC for OpenGL ([-1, 1])
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

                // Reconstruct the world space positions.
                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);

                float diff = saturate(distance(worldPos, IN.w_pos));
                float intersectGradient = 1 - min(diff / _ProjectionParams.w, 1.0f); 

                //float4 intersectTerm = _BaseColor * pow(intersectGradient, _IntersectExponent) * _IntersectIntensity;
                float4 intersectTerm = lerp(_IntersectColor * _IntersectIntensity, float4(0, 0, 0, 1), diff);
                //return intersectTerm;

                //------------------
                float4 pulseTex = tex2D(_PulseTex, IN.uv);
                float4 edgeTex = tex2D(_EdgeTex, IN.uv);
                float4 outlineTex = tex2D(_OutlineTex, IN.uv * _OutlineTex_ST.xy + _OutlineTex_ST.zw);

                float horizontalDist = abs(IN.vertexObjPos.x);
                float verticalDist   = abs(IN.vertexObjPos.z);
                float y = horizontalDist + verticalDist;

                float2 coord = IN.uv - float2(_PivotX, _PivotY);;
                float value = abs(coord.x) + abs(coord.y);
                //value = length(coord);

                float t0 = (abs((-value + _Time.y / 4) % 2 - 1) - _EdgeWidth) * (1 / (1 - _EdgeWidth));

                // faster
                t0 = smoothstep(0, 1, t0) + t0;
                t0 = 1 - frac(t0);

                //float edgeTimeFactor = max(sin(y - _Time.y * _EdgeTimeScale) - _EdgeWidth, 0.0f) * (1 / (1 - _EdgeWidth));
                float edgeTimeFactor = t0;

                float4 edgeTerm = edgeTex * _EdgeColor * _EdgeIntensity * edgeTimeFactor;
                //return edgeTerm;

                float4 pulseTerm = pulseTex * _BaseColor * _PulseIntensity * 
                                   abs(sin(_Time.y * _PulseTimeScale - horizontalDist * _PulsePosScale + pulseTex.r * _PulseTexOffsetScale));

                //return pulseTex * _BaseColor * _PulseIntensity;
                //return pulseTerm;

                //

                //float4 outlineTerm = pow(outlineTex.a, _OutlineExponent) * _BaseColor * _OutlineIntensity;

                return float4(_BaseColor.rgb + pulseTerm.rgb + edgeTerm.rgb + intersectTerm.rgb, _BaseColor.a);

                //---------------------
                // To calculate the UV coordinates for sampling the depth buffer,
                // divide the pixel location by the render target resolution
                // _ScaledScreenParams.


                // The following part creates the checkerboard effect.
                // Scale is the inverse size of the squares.
                uint scale = 10;
                // Scale, mirror and snap the coordinates.
                uint3 worldIntPos = uint3(abs(worldPos.xyz * scale));
                // Divide the surface into squares. Calculate the color ID value.
                bool white = ((worldIntPos.x) & 1) ^ (worldIntPos.y & 1) ^ (worldIntPos.z & 1);
                // Color the square based on the ID value (black or white).
                half4 color = white ? half4(1,1,1,1) : half4(0,0,0,1);

                // Set the color to black in the proximity to the far clipping
                // plane.
                #if UNITY_REVERSED_Z
                    // Case for platforms with REVERSED_Z, such as D3D.
                    if(depth < 0.0001)
                        return half4(0,0,0,1);
                #else
                    // Case for platforms without REVERSED_Z, such as OpenGL.
                    if(depth > 0.9999)
                        return half4(0,0,0,1);
                #endif

                return color;
            }
            ENDHLSL
        }
    }
}