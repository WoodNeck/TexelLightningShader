﻿Shader "Sprites/Tile" {
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
    }
    SubShader  {
    
        Tags {
            "Queue" = "Transparent"
            "RenderType" = "Opaque"
        }

        Pass {
                Tags {
                    "LightMode" = "ForwardBase"
                }
                ZWrite off
           		CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fwdbase
                
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"
                
                struct v2f {
                    float4  pos         : SV_POSITION;
                    float2  uv          : TEXCOORD0;
                    float3  lightDir    : TEXCOORD1;
                    float3  normal		: TEXCOORD2;
                    LIGHTING_COORDS(3,4)
                	float3  vertexLighting : TEXCOORD5;
                };
                
                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed4 _Color;
                fixed4 _LightColor0; 
                
                v2f vert (appdata_base v) {
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.uv = v.texcoord.xy;
					o.lightDir = ObjSpaceLightDir(v.vertex);
					o.normal = v.normal;
                    
                    TRANSFER_VERTEX_TO_FRAGMENT(o);

                    o.vertexLighting = float3(0.0, 0.0, 0.0);
		            
		            #ifdef VERTEXLIGHT_ON
  					
  					float3 worldNormal = mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL);
		          	float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
		            
		            for (int index = 0; index < 4; index++) {    
		               float4 lightPosition = float4(unity_4LightPosX0[index], 
		                  unity_4LightPosY0[index], 
		                  unity_4LightPosZ0[index], 1.0);
		 
		               float3 vertexToLightSource = float3(lightPosition - worldPos);        
		               
		               float3 lightDirection = normalize(vertexToLightSource);
		               
		               float squaredDistance = dot(vertexToLightSource, vertexToLightSource);
		               
		               float attenuation = 1.0 / (1.0  + unity_4LightAtten0[index] * squaredDistance);
		               
		               float3 diffuseReflection = attenuation * float3(unity_LightColor[index]) * float3(_Color) * max(0.0, dot(worldN, lightDirection));         
		 
		               o.vertexLighting = o.vertexLighting + diffuseReflection * 2;
		            }
		                  
		            #endif
                    
                    return o;
                }
                
                fixed4 frag(v2f i) : COLOR {
                    i.lightDir = normalize(i.lightDir);
                    fixed atten = LIGHT_ATTENUATION(i); // Macro to get you the combined shadow & attenuation value.
                    
                    fixed4 tex = tex2D(_MainTex, i.uv);
                    tex *= _Color + fixed4(i.vertexLighting, 1.0);
                  
                    fixed diff = saturate(dot(i.normal, i.lightDir));
                                        
                    fixed4 c;
                    c.rgb = (UNITY_LIGHTMODEL_AMBIENT.rgb * 2 * tex.rgb);         // Ambient term. Only do this in Forward Base. It only needs calculating once.
                    c.rgb += (tex.rgb * _LightColor0.rgb * diff) * (atten * 2); // Diffuse and specular.
                    c.a = tex.a + _LightColor0.a * atten;
                    return c;
                }
            ENDCG
        }
 
        Pass {
            Tags {
				"LightMode" = "ForwardAdd"
				"Queue"="Transparent"
				"RenderType"="Transparent"
			}                       // Again, this pass tag is important otherwise Unity may not give the correct light information.
            Blend One One                                         // Additively blend this pass with the previous one(s). This pass gets run once per pixel light.
			Cull Off
			Lighting Off
			ZWrite Off
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fwdadd                        // This line tells Unity to compile this pass for forward add, giving attenuation information for the light.
                
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"
                
                struct v2f
                {
                    float4  pos         : SV_POSITION;
                    float2  uv          : TEXCOORD0;
                    float3  lightDir    : TEXCOORD2;
                    float3 normal		: TEXCOORD1;
                    LIGHTING_COORDS(3,4)                            // Macro to send shadow & attenuation to the vertex shader.
                };
 
                v2f vert (appdata_tan v)
                {
                    v2f o;
                    
                    o.pos = UnityObjectToClipPos( v.vertex);
                    o.uv = v.texcoord.xy;
                   	
					o.lightDir = ObjSpaceLightDir(v.vertex);
					
					o.normal =  v.normal;
                    TRANSFER_VERTEX_TO_FRAGMENT(o);                 // Macro to send shadow & attenuation to the fragment shader.
                    return o;
                }
 
                sampler2D _MainTex;
                fixed4 _Color;
 
                fixed4 _LightColor0; // Colour of the light used in this pass.
 
                fixed4 frag(v2f i) : COLOR
                {
                    i.lightDir = normalize(i.lightDir);
                    
                    fixed atten = LIGHT_ATTENUATION(i); // Macro to get you the combined shadow & attenuation value.
 
                    fixed4 tex = tex2D(_MainTex, i.uv);
                    
                    tex *= _Color;
                   
					fixed3 normal = i.normal;                    
                    fixed diff = saturate(dot(normal, i.lightDir));
                    
                    
                    fixed4 c;
                    c.rgb = (tex.rgb * _LightColor0.rgb * diff) * (atten * 2); // Diffuse and specular.
                    c.a = tex.a;
                    return c;
                }
            ENDCG
        }
    }
}//Shader

//o.Specular = floor(IN.uv_MainTex.x * _MainTex_TexelSize.z) / (2 * _MainTex_TexelSize.z) + 0.5; //x
            //o.Gloss = floor(IN.uv_MainTex.y * _MainTex_TexelSize.w) / (2 * _MainTex_TexelSize.w) + 0.5;    //y