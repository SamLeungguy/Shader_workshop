Shader "MyShader/WorldScanner"
{
    Properties
    { 
        //_EdgeIntensity     ("Edge Intensity", float)       = 2.0
        //_EdgeTimeScale     ("Edge Time Scale", float)      = 2.0
        //_EdgePosScale      ("Edge Position Scale", float)  = 80.0
        //_EdgeColor         ("EdgeColor", Color)            = (0,0,0,0)
        //_EdgeWidth         ("EdgeWidth", Range(0,1))       = 20
        //_EdgeSoftness      ("EdgeSoftness", Range(0,1))    = 0.2
        //
        //_PulseTex      ("Pulse Texture", 2D)                      = "white" {}
        //_PulseIntensity("Pulse Intensity", float)                 = 3.0
        //_PulseTimeScale("Pulse Time Scale", float)                = 2.0
        //_PulsePosScale ("Pulse Position Scale", float)            = 50.0
        //_PulseTexOffsetScale("Pulse Texture Offset Scale", float) = 1.5
        //
        //_OutlineTex         ("Outline Texture", 2D) = "white" {}
        //_OutlineIntensity   ("Outline Intensity", float) = 10.0
        //_OutlineExponent    ("Outline Falloff Exponent", float) = 6.0
        //-------------

        [HideInInspector]_MainTex ("Texture", 2D) = "white" {}
        [Header(Wave)]
        _WaveDistance ("Distance from player", float) = 10
        _WaveTrail ("Length of the trail", Range(0,5)) = 1
        _WaveColor ("Color", Color) = (1,0,0,1)

        _BaseColor     ("BaseColor", Color)         = (1,0,0,1)

        _IntersectColor     ("IntersectColor", Color)                = (1,0,0,1)
        _IntersectIntensity ("Intersection Intensity", float)        = 10.0
        _IntersectExponent  ("Intersection Falloff Exponent", float) = 6.0

        _EdgeTex           ("Edge Texture", 2D)            = "white" {}
        _EdgeColor      ("EdgeColor", Color)         = (1,0,0,1)
        _EdgeWidth      ("EdgeWidth", Range(0,40))   = 20
        _EdgeSoftness   ("EdgeSoftness", Range(0,1)) = 0.2
        _Radius         ("Radius", Range(0,100))     = 20

        _ScannerCenter  ("ScannerCenter", Vector)    = (0, 0, 0, 0)

        _MyTime         ("My time", Range(0,400))      = 0
       	_PivotX         ("PivotX", range(0, 1))        = 0.5
		_PivotY         ("PivotY", range(0, 1))        = 0.5
        _DepthOffset    ("DepthOffset", range(0, 10))  = 1
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _WaveDistance;
            float _WaveTrail;
            float4 _WaveColor;

            // eddge
            sampler2D _EdgeTex;
            float4 _EdgeTex_ST;
            float4 _EdgeColor; 

            float _EdgeWidth;    
            float _EdgeSoftness; 
            float _Radius;

            float4 _IntersectColor;
            float _IntersectIntensity;
            float _IntersectExponent;

            float4 _ScannerCenter;

            float4 _BaseColor;

            float _MyTime;
            float _PivotX;
            float _PivotY;
            float _DepthOffset;

            float4 getMatrixTranslate(float4x4 m)
            {
                return m._m03_m13_m23_m33;
            }

            float invLerp(float from, float to, float value){
				return (value - from) / (to - from);
			}

            // The vertex shader definition with properties defined in the Varyings
            // structure. The type of the vert function must match the type (struct)
            // that it returns.
            Varyings vert(Attributes i)
            {
                // Declaring the output object (OUT) with the Varyings struct.
                Varyings o;
                // The TransformObjectToHClip function transforms vertex positions
                // from object space to homogenous clip space.
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);

                //o.positionHCS = i.positionOS;

                // Returning the output.
                o.vertexObjPos = i.positionOS;

                o.uv = TRANSFORM_TEX(i.uv, _EdgeTex);

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

                // To calculate the UV coordinates for sampling the depth buffer,
                // divide the pixel location by the render target resolution
                // _ScaledScreenParams.
                float2 UV = i.positionHCS.xy / _ScaledScreenParams.xy;
                
                // Sample the depth from the Camera depth texture.
                #if UNITY_REVERSED_Z
                    real depth = SampleSceneDepth(UV);
                #else
                    // Adjust Z to match NDC for OpenGL ([-1, 1])
                    real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                #endif

                //depth = Linear01Depth(depth);
                //depth as distance from camera in units
                //depth = depth * _ProjectionParams.z;
                float waveFront = step(depth, _WaveDistance);
                float waveTrail = smoothstep(_WaveDistance - _WaveTrail, _WaveDistance, depth);
                float wave = waveFront * waveTrail;

                return wave;

                float2 coord = i.uv - float2(_PivotX, _PivotY);;
                float value = abs(coord.x) + abs(coord.y);
                //value = length(coord);

                float horizontalDist = abs(i.vertexObjPos.x);
                float verticalDist   = abs(i.vertexObjPos.z);
                float y = horizontalDist + verticalDist;

                float4 objectWorldPos = getMatrixTranslate(unity_ObjectToWorld);

                float3 scanner_pos = objectWorldPos.xyz + _ScannerCenter.xyz;

                // Reconstruct the world space positions.
                float3 worldPos = ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
                //return float4(worldPos, 1);

                float innerRadius = _Radius - _EdgeWidth;

                //float dist = distance(worldPos, scanner_pos);

                float dist = distance(worldPos, i.w_pos);
                //dist = _Radius * _Radius - dist;

                dist = saturate(dist);

                float inner_bound  = innerRadius * innerRadius - dist;
                float outter_bound = _Radius * _Radius - dist;
                float d = outter_bound - inner_bound;

                float w = invLerp(inner_bound, outter_bound, _EdgeSoftness);

                //w = saturate(w);


                float diff = _Radius * _Radius - dist;
                //float intersectGradient = 1 - min(diff / _ProjectionParams.w, 1.0f);

                diff = 1 - saturate(diff);
                
                float4 edgeTex = tex2D(_EdgeTex, i.uv);

                

                //float4 intersectTerm = _BaseColor * pow(intersectGradient, _IntersectExponent) * _IntersectIntensity;
                float4 intersectTerm = lerp(edgeTex * _IntersectIntensity, float4(0, 0, 0, 1), dist);
                //float4 intersectTerm = lerp(float4(0, 0, 0, 1), edgeTex, dist);

                return intersectTerm;

                //--------------


                //------------------

                //---------------------

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


            }
            ENDHLSL
        }
    }
}