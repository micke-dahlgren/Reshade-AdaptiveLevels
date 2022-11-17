#include "ReShadeUI.fxh"

// uniform int UI_TEST <
// 	ui_type = "combo";
// 	ui_label = "Source of the mask";
// 	ui_items = "Performance\0" 
// 						 "Balanced\0"	
// 						 "Ultra\0";	
// > = 1;

uniform float UI_Strength < __UNIFORM_SLIDER_FLOAT1
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Effect Mix";
	ui_tooltip = "How much of the effects that are mixed in with the image";
> = 1;


uniform float UI_Black_Mix < __UNIFORM_SLIDER_FLOAT1
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Adjust the strength of the black level adjustments";
	ui_label = "Darkening Mix";
> = 1;

uniform float UI_White_Mix < __UNIFORM_SLIDER_FLOAT1
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "Adjust the strength of the white level adjustments";
	ui_label = "Brightening Mix";
> = 1;

uniform int UI_Black_Limit < __UNIFORM_SLIDER_INT1
	ui_category = "Level Limits";
	ui_type = "drag";
	ui_min = 0; ui_max = 255; ui_step=1;
	ui_tooltip = "How much the darkness level is allowed to be adjusted. 255 means no limit";
	ui_label = "Darkening Limit";
> = 32;

uniform int UI_White_Limit < __UNIFORM_SLIDER_INT1
	ui_category = "Level Limits";
	ui_type = "drag";
	ui_min = 0; ui_max = 255; ui_step=1;
	ui_tooltip = "How much the brightness level is allowed to be adjusted. 0 means no limit";
	ui_label = "Brightening Limit ";
> = 200;

uniform float UI_Adaption_Speed < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Adjustments";
	ui_type = "slider";
	ui_label = "Adaptions Speed";
	ui_tooltip = "How fast the adaption will be. Lower is faster";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.01;
> = 0.85;


uniform float UI_Saturation < __UNIFORM_SLIDER_FLOAT1
	ui_category = "Adjustments";
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_tooltip = "0 = only perform leveling on luma values. 1 = perform leveling on both chroma and luma";
	ui_label = "Saturation ";
> = 0.5;


uniform int2 UI_Screen_Edge_Dodge < __UNIFORM_INPUT_INT1
	ui_text = "\n Adjust these if you have UI elements or borders that breaks this effect";
	ui_category = "Sample Dodge";
	ui_type = "input";
	ui_min = 0; ui_max = 100;
	ui_tooltip = "This Removes sample points from the edges of the screen. Useful for when ex: sample source picks up on UI HUD. Check 'Visualize sample source' to see the effect";
	ui_label = "Screen Edge Dodge";
> = 0;

uniform int UI_Screen_Center_Dodge < __UNIFORM_INPUT_INT1
	ui_category = "Sample Dodge";
	ui_type = "input";
	ui_min = 0; ui_max = 100;
	ui_tooltip = "This Removes sample points from the center of the screen. Useful for when ex: sample source picks up on reticle. Check 'Visualize sample source' to see the effect";
	ui_label = "Screen Center Dodge";
> = 0;

uniform int UI_DEBUG_VIEW <
	ui_type = "combo";
	ui_label = "Source of the mask";
	ui_items = "None\0" 
						 "Sample Source\0"	
						 "Input Levels\0";	
> = 0;


namespace UI_Utility{
	bool isEffectInvisible(){
		return(
			UI_Strength <= 0 || 
			((UI_Black_Mix == 0 || UI_Black_Limit == 0) && 
			(UI_White_Mix == 0 || UI_White_Limit == 255))
			);
	}
}