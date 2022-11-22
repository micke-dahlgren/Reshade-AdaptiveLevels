/**
 * Adaptive Levels
 * by Mikael Dahlgren ~ zoidbun
 * https://github.com/micke-dahlgren
 */

#include "ReShade.fxh"
#include "./AdaptiveLevelsDev/AdaptiveLevelsUI.fxh";
#include "./AdaptiveLevelsDev/Adapt.fxh";
uniform float FRAMETIME < source = "frametime";>;

#define NEUTRAL_LEVELS float3(0, 1, 0.5)
#ifndef AL_RESOLUTION_X
  #define AL_RESOLUTION_X     16    // [2 to BUFFER_WIDTH] The amount of horizontal sample points
#endif   
#ifndef AL_RESOLUTION_Y
  #define AL_RESOLUTION_Y     8    // [2 to BUFFER_HEIGHT] The amount of vertical sample points ss
#endif   

texture SourceForLevelGatheringTarget { Width = AL_RESOLUTION_X; Height = AL_RESOLUTION_Y; };
sampler SourceForLevelGatheringSampler { 
  Texture = SourceForLevelGatheringTarget; 
  MagFilter = POINT; 
  MinFilter = POINT; 
  MipFilter = POINT;
};
      
texture2D PrevLevelDataTarget { Width = 1; Height = 1; };
sampler PrevLevelDataSampler { Texture = PrevLevelDataTarget; };

texture2D CurrLevelDataTarget { Width = 1; Height = 1; };
sampler CurrLevelDataSampler { Texture = CurrLevelDataTarget;};

void GetSourceForLevelGathering(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 output : SV_Target){
  output = tex2D(ReShade::BackBuffer, texcoord);
}


float3 DebugViz(float2 pos, float2 texcoord, float3 levels, float3 outcol){
  if(UI_DEBUG_VIEW == 1){
    float2 sampSize = float2(BUFFER_WIDTH / AL_RESOLUTION_X, BUFFER_HEIGHT / AL_RESOLUTION_Y);
    if(UI_Screen_Edge_Dodge.x > 0 || UI_Screen_Edge_Dodge.y > 0){
      if(pos.x-2 <= sampSize.x * UI_Screen_Edge_Dodge.x || pos.x+2 >= BUFFER_WIDTH - sampSize.x * UI_Screen_Edge_Dodge.x){
        return C_BLACK;
      }
      if(pos.y <= sampSize.y * UI_Screen_Edge_Dodge.y || pos.y >= BUFFER_HEIGHT - sampSize.y * UI_Screen_Edge_Dodge.y){
        return C_BLACK;
      }
    }
    
      bool yCenter = pos.y >= sampSize.y*(AL_RESOLUTION_Y/2) - sampSize.y*UI_Screen_Center_Dodge && pos.y <= sampSize.y*(AL_RESOLUTION_Y/2) + sampSize.y*UI_Screen_Center_Dodge ; 
      bool xCenter = pos.x >= sampSize.x*(AL_RESOLUTION_X/2) - sampSize.x*UI_Screen_Center_Dodge && pos.x <= sampSize.x*(AL_RESOLUTION_X/2) + sampSize.x*UI_Screen_Center_Dodge ; 
      if(xCenter && yCenter){
        return C_BLACK;
      }
    return tex2D(SourceForLevelGatheringSampler, texcoord).rgb;
  }
  // debug levels
  if(UI_DEBUG_VIEW == 2){

    int levelBlockSize = floor(BUFFER_WIDTH*0.1);
    int2 xPos = int2(BUFFER_WIDTH - levelBlockSize, BUFFER_WIDTH);
    int2 yPos = int2(BUFFER_HEIGHT - levelBlockSize, BUFFER_HEIGHT);
    if(pos.x >= xPos.x && pos.x <= xPos.y && pos.y >= yPos.x && pos.y <= yPos.y){
      return levels.x;
    }
    xPos -= levelBlockSize;
    if(pos.x >= xPos.x && pos.x <= xPos.y && pos.y >= yPos.x && pos.y <= yPos.y){
      return levels.y;
    }
  }
  return outcol;
} 

float3 WriteToCurrLevelData(float4 pos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
  if(UI_Utility::isEffectInvisible()){discard;}
  float3 prevLevels = tex2Dfetch(PrevLevelDataSampler, float2(0,0)).rgb; 
  float3 currLevels;
  Adapt::GetLevels(pos, SourceForLevelGatheringSampler, currLevels);
  float dt = FRAMETIME * 0.001;
  float adaptionSpeed = saturate(dt / max(UI_Adaption_Speed, 0.001));
  return lerp(prevLevels, currLevels, adaptionSpeed);
} 
     
float3 Main(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  if(UI_Utility::isEffectInvisible()){discard;}
  // apply levels 
  float3 original = tex2D(ReShade::BackBuffer, texcoord).rgb;
  float3 luma = lerp(dot(original, LUMCOEFF), original, UI_Saturation);
  float3 chroma = original - luma;
  float3 levels = tex2D(CurrLevelDataSampler, float2(0,0));
  
  luma = Adapt::ApplyLevels(luma, levels, texcoord);
   
  // bring back color
  float3 color = saturate(luma + chroma); 

  // debug sample source
  if(UI_DEBUG_VIEW != 0){
    return DebugViz(pos, texcoord, levels, original);
  }
  return lerp(original,color,UI_Strength);
}

void StoreCurrLevelDataInPrev(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float3 res : SV_Target) 
{
  res = tex2D(CurrLevelDataSampler, float2(0,0)).rgb;
}

technique AdaptiveLevels < ui_tooltip = "Automatically set levels"; >
{
  pass CreateSourceForLevelGathering
	{
		VertexShader = PostProcessVS;
		PixelShader = GetSourceForLevelGathering;						
		RenderTarget = SourceForLevelGatheringTarget;
	}

  pass StoreCurrLevels
  {
    VertexShader = PostProcessVS;
    PixelShader = WriteToCurrLevelData;
    RenderTarget = CurrLevelDataTarget;
  }

  pass Main
  {
    VertexShader = PostProcessVS;
    PixelShader = Main;
  }

  pass StorePrevLevels
  {
    VertexShader = PostProcessVS;
    PixelShader = StoreCurrLevelDataInPrev;
    RenderTarget = PrevLevelDataTarget;
  }

}
