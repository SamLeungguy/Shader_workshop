Shader "MyShader/MyNormalMap"
{
    Properties
    { 

         _MainTex             ("Main Texture", 2D)          = "white" {}
         _NormalTex           ("Normal map", 2D)            = "white" {}
         myLocator("myLocator", Vector) = (0,0,0,1)
        //----------------
        _BaseColor ("BaseColor", Color)         = (1,0,0,1)
        _MyTime         ("My time", Range(0,400))      = 0
    }

    // The SubShader block containing the Shader code.
    SubShader
    {
        // SubShader Tags define when and under which conditions a SubShader block or
        // a pass is executed.
        Tags { "RenderType" = "Opaque" "Queue" = "Transparent" "RenderPipeline" = "UniversalPipeline"  }

        Pass
        {

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            //#include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                // The positionOS variable contains the vertex positions in object
                // space.
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                float3 normal       : NORMAL;
                float3 tangent      : TANGENT;
            };

            struct Varyings
            {
                // The positions in this struct must have the SV_POSITION semantic.
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float4 vertexObjPos : TEXCOORD1;
                float3 w_pos        : TEXCOORD2;
                float3 w_normal     : TEXCOORD3;
                float3x3 tbn        : TEXCOORD4;
            };

            struct MyLight
            {
                float4 color;
                float3 position;
                float3 direction;
            
                float innerCutoff;
                float outerCutoff;
            
                int type;
            };
             //MyLight _MyLights[MAX_LIGHTS_COUNT];

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalTex;
            float4 _NormalTex_ST;

            float4 light_pos;
            float4 myLocator;


            float _MyTime;
            float4 _BaseColor;


             //---------
            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);
                o.vertexObjPos = i.positionOS;

                o.uv = i.uv;
                o.w_normal = TransformObjectToWorldNormal(i.normal);

                o.w_pos = TransformObjectToWorld(i.positionOS.xyz);

                float3 b = cross(o.w_normal, i.tangent);
                float3 T = normalize(TransformObjectToWorldNormal(i.tangent));
                float3 B = normalize(TransformObjectToWorldNormal(b));
                float3 N = normalize(o.w_normal);
                o.tbn = float3x3(T, B, N);

                return o;
            }

            float4 frag(Varyings i) : SV_Target
            {
                static const float epsilon = 0.0001f;

                float3 normal = tex2D(_NormalTex, i.uv).rgb;
                normal = normal * 2.0 - 1.0;
                normal = normalize(mul(normal, i.tbn));

                float4 tex = tex2D(_MainTex, i.uv);

                //float3 L;
                float dist;
                float attenuation = 1.0f;
                
                float3 L = normalize(myLocator.xyz - i.w_pos);
                float3 N = normalize(normal);
                float3 V = normalize(i.w_pos - _WorldSpaceCameraPos);
                float3 R = reflect(L, N);

                //float3 ambient  = _AmbientColor * _AmbientIntensity;
                float3 diffuse  = tex.rgb * max(dot(L, N), 0) * 0.7;
                float3 specular = float3(1, 1, 1) * pow(max(dot(V, R), 0), 40) * 0.3;

                float4 color = 0;
                //color.rgb += ambient;
                color.rgb += diffuse;
                color.rgb += specular;

                //return float4(myLocator.x, 0, 0, 1);

                return color * attenuation;
            }
            ENDHLSL
        }
    }
}