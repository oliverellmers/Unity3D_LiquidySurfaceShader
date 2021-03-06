﻿Shader "Custom/LiquidySurface" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BumpMap("Bumpmap", 2D) = "bump" {}
		_Glossiness("Smoothness", Range(0,1)) = 1.0
		_Metallic("Metallic", Range(0,1)) = 0.0
	}
		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 300


		CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Standard fullforwardshadows vertex:vert tessellate:tessEdge tessphong:0.5
			#pragma target 4.6
			#include "Tessellation.cginc"

		sampler2D _MainTex;
		sampler2D _BumpMap;
		samplerCUBE _Cube;

		struct appdata {
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
		};

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 worldRefl;
			float3 viewDir;
			float3 worldPos;
			INTERNAL_DATA
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		float uTesselPhong;
		float uTesselEdge;
		float uTime;
		float uVol;
		float uNormalInverse;
		float uRotRad;
		float3 uRotAxis;

		const float PI = 3.14159265;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		float4x4 rotationMatrix(float3 axis, float angle)
		{
			axis = normalize(axis);
			float s = sin(angle);
			float c = cos(angle);
			float oc = 1.0 - c;

			return float4x4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
				oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
				oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0,
				0.0, 0.0, 0.0, 1.0);
		}

		float4 tessEdge(appdata v0, appdata v1, appdata v2)
		{
			return UnityEdgeLengthBasedTess(v0.vertex, v1.vertex, v2.vertex, uTesselEdge);
		}

		void vert(inout appdata v)
		{
			float2 coords = v.texcoord.xy;
			coords.x = frac((coords.x - .5) * 2.);

			float d = length(tex2Dlod(_BumpMap, float4(coords, 0, 0)).rgb) * .02 * (uNormalInverse-.5)*2.;
			v.vertex.xyz += v.normal * d;
			v.vertex.xyz += v.normal * uVol * .03;

			v.vertex.xyz = mul(
				rotationMatrix(uRotAxis, uTime * -.001 + uRotRad), float4(v.vertex.xyz, 1.)).xyz;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			float2 coords = IN.uv_MainTex;
			coords.x = frac((coords.x - .5) * 2.);

			fixed4 c = tex2D (_MainTex, coords) * _Color;
			o.Albedo = c.rgb;

			coords = IN.uv_BumpMap;
			coords.x = frac((coords.x - .5) * 2.);

			o.Normal = UnpackNormal(tex2D(_BumpMap, coords));

			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			
			float3 mCube = texCUBE(_Cube, WorldReflectionVector(IN, o.Normal)).rgb * .3;
			o.Emission = mCube;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
