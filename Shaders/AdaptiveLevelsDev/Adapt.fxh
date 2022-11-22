#define C_BLACK float3(0,0,0)
#define LUMCOEFF float3(0.212656, 0.715158, 0.072186)
uniform float FRAMECOUNT < source = "framecount"; >;

namespace Adapt {
  
  struct LoopExpression
  {
    int2 start, end, center;
    int iterator;
  };

  LoopExpression getLoopExpression(float2 sampSize){
    LoopExpression LE;
    
    LE.start = int2(
      0 + UI_Screen_Edge_Dodge.x, 
      0 + UI_Screen_Edge_Dodge.y
    );
    
    
    LE.end = int2(
      sampSize.x - UI_Screen_Edge_Dodge.x - 1, 
      sampSize.y - UI_Screen_Edge_Dodge.y - 1
    );

    LE.center = int2(
      floor(LE.end.x / 2),
      floor(LE.end.y / 2)
    );
    LE.iterator = 1;
    return LE;
  }

  float3 getMinMax(sampler samp, int2 sampleCoord, float3 levels){
      float luma = dot(tex2Dfetch(samp, floor(sampleCoord)).rgb,LUMCOEFF);
      levels.x = min(luma, levels.x);
      levels.y = max(luma, levels.y);
      return levels;
  }

  void doLoop(float4 pos, LoopExpression LE, sampler samp, float2 sampSize, inout float3 levels){
    float2 sampleCoord;
    bool dodgeCenter = UI_Screen_Center_Dodge > 0;
    bool yCenter = false;
    bool xCenter = false;
    for(int x = LE.start.x; x <= LE.end.x; x += LE.iterator){
      sampleCoord.x = x + 0.5;
      if(dodgeCenter){
        xCenter = (x >= LE.center.x - UI_Screen_Center_Dodge && x <= LE.center.x + UI_Screen_Center_Dodge);
      }
      for(int y = LE.start.y; y <= LE.end.y; y++){
        sampleCoord.y = y + 0.5;
        if(dodgeCenter && xCenter){
          yCenter = (y >= LE.center.y - UI_Screen_Center_Dodge && y <= LE.center.y + UI_Screen_Center_Dodge);
          if(yCenter){
            xCenter = false;
            xCenter = false;
            continue; // ensures we dont count this value for
          }
        }
        levels = getMinMax(samp, sampleCoord, levels);
        
        // bail out of loop if we've found values beyond the defined limits
        if(levels.x >= UI_Black_Limit && levels.y <= UI_White_Limit){
          break;
        }
      }
      if(levels.x >= UI_Black_Limit && levels.y <= UI_White_Limit){
        break;
      }
    };
  } 



void GetLevels(float4 pos, sampler samp, out float3 ret)
	{
    // [0]: darkest value, [2]: brightest value, [3]: unused, reserved for avg value
    float3 levels = float3(1,-1,0);

    LoopExpression loopExp;
    float2 sampSize = tex2Dsize(samp);
    loopExp = getLoopExpression(sampSize);
    doLoop(pos, loopExp, samp, sampSize, levels);

		ret = levels;
	}

  float3 ApplyLevels(float3 luma, float3 levels, float2 texcoord){
    float BlackPoint = lerp(0, levels.x, UI_Black_Mix);
    float WhitePoint = lerp(1, levels.y, UI_White_Mix); 

    BlackPoint = min(BlackPoint, UI_Black_Limit/255.0);
    WhitePoint = max(WhitePoint, UI_White_Limit/255.0);

    if (BlackPoint == WhitePoint){WhitePoint += 1;}
    float bp = BlackPoint;
    float wp = 1 / (WhitePoint - BlackPoint);
    return saturate(luma * wp - (bp *  wp));

  }

}

