local _l_exposure_LUT = {
--        exposure
        { 0.05,   1.00, 0.50,    0.420, 1.00, 1.00, 0.00  },
        { 0.065,  0.98, 0.46,    0.410, 1.00, 1.00, 0.00  },
        { 0.075,  0.92, 0.44,    0.360, 1.00, 0.90, 0.00  },
        { 0.087,  0.81, 0.40,    0.330, 1.00, 0.75, 0.00  },
        { 0.1,    0.70, 0.35,    0.290, 1.00, 0.50, 0.05  },
        { 0.15,   0.63, 0.22,    0.227, 0.75, 0.20, 0.15  },
        { 0.2,    0.55, 0.10,    0.260, 0.25, 0.05, 0.30  },
        { 0.3,    0.50, 0.10,    0.255, 0.00, 0.00, 0.60  },
        { 0.5,    0.50, 0.10,    0.250, 0.00, 0.00, 1.00  },
        { 1.0,    0.50, 0.10,    0.250, 0.00, 0.00, 1.00  },
    }
local _l_Exposure_result
local _l_ExposureCPP = LUT:new(_l_exposure_LUT)


local godrays_length = 0

function init_pure_script()

    __PURE__set_config("light.daylight_multiplier", 0.817, true)
    __PURE__set_config("light.sun.saturation", 0.865, true)
    __PURE__set_config("light.sun.level", 0.8, true)
    __PURE__set_config("csp_lights.bounce", 2.2, true)
    __PURE__set_config("csp_lights.emissive", 2.5, true)
    __PURE__set_config("csp_lights.displays", 0.288, true)
    __PURE__set_config("reflections.saturation", 0.865, true)
    __PURE__set_config("reflections.level", 1.57, true)
    __PURE__set_config("clouds2D.brightness", 1.2, true)
    __PURE__set_config("clouds2D.contrast", 1.1, true)
    __PURE__set_config("nlp.lowest_ambient", 5.4, true)


    PURE__use_ExpCalc(true)

    if PURE__getPP_enabled() then
        local exp 		= Pure_get_PPfilter_entry("TONEMAPPING","EXPOSURE") or 0.3
        local gamma 	= Pure_get_PPfilter_entry("TONEMAPPING","GAMMA") or 1.0
        local ae 		= Pure_get_PPfilter_entry("AUTO_EXPOSURE","ENABLED") or 0
        local target 	= Pure_get_PPfilter_entry("AUTO_EXPOSURE","TARGET") or 0.3

        local tmp = 0.3
        if ae>0 then
            tmp = target
        else
            tmp = exp
        end
        PURE__ExpCalc_set_Multiplier(1+(tmp-0.3)+(negative_pow((3*(1.2-math.pow(gamma, 0.4))), 0.76)))
        PURE__ExpCalc_set_Target(1.0)

        -- modulate pp brightness to compensate the setting in the ppfilter file
        __PURE__set_config("pp.brightness", 1+(Pure_get_PPfilter_entry("COLOR","BRIGHTNESS")-1)*0.5, true)

        godrays_length = Pure_get_PPfilter_entry("GODRAYS","LENGTH") or 5
    end

        __SCRIPT__setVersion(2.1)
    __SCRIPT__ResetSettingsWithNewVersion()

    __SCRIPT__UI_SliderFloat("Exposure Adaption Interior", 0.90, 0.0, 1.0)
    __SCRIPT__UI_SliderFloat("Exposure Adaption Exterior", 0.50, 0.0, 1.0)
    __SCRIPT__UI_Separator()

    __SCRIPT__UI_Checkbox("Exposure Adaption", true)
    __SCRIPT__UI_Checkbox("Spectrum Adaption", true)
    __SCRIPT__UI_Checkbox("VAO Adaption", false)

end

local _l_tmp_hsv = hsv(0,0,0)
local _l_tmp_rgb = rgb(0,0,0)

function update_pure_script(dt)


    __SCRIPT__UI_setValue("Final Exposure", PURE__ExpCalc_get_final_exposure())

    -- uses Pure's exposure calculation via Cubemap Brightness Estimation
    PURE__use_ExpCalc(__SCRIPT__UI_getValue("Exposure Adaption"))

    -- this will compensate the spectrum with missing sunlight in overcast sceneries
    PURE__use_SpectrumAdaption(__SCRIPT__UI_getValue("Spectrum Adaption"))

    -- this adapts the VAO parameters with overcast sceneries
    PURE__use_VAOAdaption(__SCRIPT__UI_getValue("VAO Adaption"))

    if PURE__getPP_enabled() then
        ac.setGodraysLength( godrays_length * PURE__getGodraysModulator() )
    end

if __SCRIPT__UI_getValue("Exposure Adaption") then
    if ac.isInteriorView() then
        local interior_mix = __SCRIPT__UI_getValue("Interior multiplier")
        __SCRIPT__UI_setValue("Exposure Adaption", interior_mix)
        PURE__set_ExpCalc(interior_mix)
    else
        local exterior_mix = __SCRIPT__UI_getValue("Exterior multiplier")
        __SCRIPT__UI_setValue("Exposure Adaption", exterior_mix)
        PURE__set_ExpCalc(exterior_mix)
    end
else
    PURE__set_ExpCalc(0)
end

--[[
    -- compensate godrays color / remove the reddish shine a bit
    -- convert the light source color into HSV format
    RGBToHSV_To(_l_tmp_hsv, Pure_getColor(COLORS.LIGHTSOURCE))
    -- do some modulations
    _l_tmp_hsv.h = _l_tmp_hsv.h + 12.5 * (1 - sun_compensate(0))
    _l_tmp_hsv.v = _l_tmp_hsv.v * sun_compensate(0.5) * 0.1
    _l_tmp_hsv.s = _l_tmp_hsv.s * __IntD(1.0, 0.5, 0.35)
    -- convert it back to RGB
    HSVToRGB_To(_l_tmp_rgb, _l_tmp_hsv.h, _l_tmp_hsv.s, _l_tmp_hsv.v)
    -- set the godrays color
    ac.setGodraysCustomColor(_l_tmp_rgb)
]]
end

    -- Pure get/set functions
    --[[

        -- CAMERA functions

        Pure_getVector(VECTORS.CAM_DIR) --vec3
        Pure_getVector(VECTORS.CAM_POS) --vec3
        Pure__get_camFOV() --float


        -- Autoexposure

        Pure_get_AE_target()
        Pure_set_AE_target(v)


        -- Lighting
        -- use those ids to retrieve Pure's colors
        COLORS.LIGHTSOURCE
        COLORS.AMBIENT
        COLORS.DIRECTIONAL_AMBIENT
        COLORS.SUN
        COLORS.MOON
        COLORS.NLP
        -- with the function:
        Pure_getColor(id)

        e.g.:
        ac.setGodraysCustomColor(Pure_getColor(COLORS.LIGHTSOURCE):scale(0.125))
}
    ]]




    -- direct wfx PP functions
    --[[  You can use this weatherFX functions to set and get PP Filter values:

        SET

		    ac.resetSpecularColor()
            ac.setSpecularColor(c: rgb)
            ac.resetEmissiveMultiplier()
            ac.setEmissiveMultiplier(v: number)
            ac.resetReflectionEmissiveBoost()
            ac.setReflectionEmissiveBoost(v: number)
            ac.resetGlowBrightness()
            ac.setGlowBrightness(v: number)
            ac.resetGodraysCustomColor()
            ac.setGodraysCustomColor(c: rgb)
            ac.resetGodraysCustomDirection()
            ac.setGodraysCustomDirection(v: vec3)
            ac.setGodraysLength(v: number)
            ac.setGodraysGlareRatio(v: number)
            ac.setGodraysAngleAttenuation(v: number)
            ac.setGodraysNoiseFrequency(v: number)
            ac.setGodraysNoiseMask(v: number)
            ac.setGodraysDepthMapThreshold(v: number)
            ac.setGlareThreshold(v: number)
            ac.setGlareBloomFilterThreshold(v: number)
            ac.setGlareBloomLuminanceGamma(v: number)
            ac.setGlareStarFilterThreshold(v: number)
            ac.setPpColorTemperatureK(v: number)
            ac.setPpWhiteBalanceK(v: number)
            ac.setPpHue(v: number)
            ac.setPpSepia(v: number)
            ac.setPpSaturation(v: number)
            ac.setPpBrightness(v: number)
            ac.setPpContrast(v: number)
            ac.setPpTonemapFunction(v: ac.TonemapFunction)
            ac.setPpTonemapExposure(v: number)
            ac.setPpTonemapGamma(v: number)
            ac.setPpTonemapUseHdrSpace(v: boolean)
            ac.setPpTonemapMappingFactor(v: number)
            ac.setPpTonemapFilmicContrast(v: number)
            ac.setPpColorGradingIntensity(v: number)
            ac.setPpWhiteBalanceK(v: number)
	        ac.setPpColorTemperatureK(v: number)


        GET

            ac.getGodraysLength(): number
            ac.getGodraysGlareRatio(): number
            ac.getGodraysAngleAttenuation(): number
            ac.getGodraysNoiseFrequency(): number
            ac.getGodraysNoiseMask(): number
            ac.getGodraysDepthMapThreshold(): number
            ac.getGlareThreshold(): number
            ac.getGlareBloomFilterThreshold(): number
            ac.getGlareStarFilterThreshold(): number
            ac.getPpColorTemperatureK(): number
            ac.getPpWhiteBalanceK(): number
            ac.getPpHue(): number
            ac.getPpSepia(): number
            ac.getPpSaturation(): number
            ac.getPpBrightness(): number
            ac.getPpContrast(): number
            ac.getPpAutoExposureEnabled(): boolean
            ac.getAutoExposure(): number
            ac.getPpTonemapFunction(): number
            ac.getPpTonemapExposure(): number
            ac.getPpTonemapGamma(): number
            ac.getPpTonemapMappingFactor(): number
            ac.getPpTonemapFilmicContrast(): number
            ac.getPpTonemapUseHdrSpace(): number
            ac.getPpGodraysEnabled(): boolean
            ac.getPpDofEnabled(): boolean
            ac.getPpDofActive(): boolean
            ac.getPpChromaticAbberationActive(): boolean
            ac.getPpGlareGhostActive(): boolean
            ac.getPpHeatParticleActive(): boolean
            ac.getPpAirydiskEnabled(): boolean
            ac.getPpAntialiasingEnabled(): boolean
            ac.getPpChromaticAbberationEnabled(): boolean
            ac.getPpFeedbackEnabled(): boolean
            ac.getPpLensDistortionEnabled(): boolean
            ac.getPpHeatParticleEnabled(): boolean
            ac.getPpGlareEnabled(): boolean
            ac.getPpGlareAnamorphicEnabled(): boolean
            ac.setPpTonemapViewportScale(v: vec2)
            ac.setPpTonemapViewportOffset(v: vec2)
	]]

	--[[ Using weatherFX's color corrections

		local filter = ac.ColorCorrectionGrayscale {  }
		local filter = ac.ColorCorrectionNegative {  }

		local filter = ac.ColorCorrectionSepiaTone { value = 0 }
		local filter = ac.ColorCorrectionBrightness { value = 0 }
		local filter = ac.ColorCorrectionSaturation { value = 0 }
		local filter = ac.ColorCorrectionContrast { value = 0 }
		local filter = ac.ColorCorrectionBias { value = 0 }

		local filter = ac.ColorCorrectionModulationRgb { color = rgb(1,1,1) }
		local filter = ac.ColorCorrectionSaturationRgb { color = rgb(1,1,1) }
		local filter = ac.ColorCorrectionContrastRgb { color = rgb(1,1,1) }
		local filter = ac.ColorCorrectionBiasRgb { color = rgb(1,1,1) }

		local filter = ac.ColorCorrectionMonotoneRgb { color = rgb(1,1,1), effectRation = 0 }
		local filter = ac.ColorCorrectionMonotoneRgbSatMod { color = rgb(1,1,1), saturation = 0, modulation = 0 }
		local filter = ac.ColorCorrectionFadeRgb { color = rgb(1,1,1), effectRation = 0 }
		local filter = ac.ColorCorrectionHue { hue = 0, keepLuminance = 0 }
		local filter = ac.ColorCorrectionHue { hue = 0, saturation = 0, brightness = 1 }

		local filter = ac.ColorCorrectionTemperature { temperature = 6500, luminance = 0 }
		local filter = ac.ColorCorrectionWhiteBalance { temperature = 6500, luminance = 0 }

		ac.weatherColorCorrections[#ac.weatherColorCorrections + 1] = filter


		Example:
			
			At beginning of custom config:

			local filter_bias = ac.ColorCorrectionBiasRgb { color = rgb(1,1,1) }
			ac.weatherColorCorrections[#ac.weatherColorCorrections + 1] = filter_bias

			local color_bias_low = rgb(0.1,0,0)
			local color_bias_high = rgb(0,0,0.1)


			In update_sol_custom_config():

			filter_bias.color = math.lerp(color_bias_low, color_bias_high, from_twilight_compensate(0))
	]]


	--##############################################################################################
	--[[  This are some functions, to create dependencies to the sunangle
		
		The compensate function returning the given value or 1 (its mainly used as an multiplicator)

		- transition between v and 1 is with sunangles between -6° and -12°
		day_compensate(v)   - returns 1 while day | v while night
		night_compensate(v) - returns 1 while night | v while day

		- transition between v and 1 is with sunangles between +3° and -6°
		from_twilight_compensate(v)  - returns 1 while day | v while night

		- transition between v and 1 is with sunangles between +6° and 0°
		sun_compensate(v)   - returns 1 with sun | v when sun is < 0°

		- transition between v and 1 is with sunangles between +10° and -11°
		duskdawn_compensate(v)  - returns 1 while dusk or dawn
		
		- transition between v and 1 is with sunangles between +30°->+10° and -9°->-20°
		dawn_exclusive(v) 	- returns 1 while not in dawn
		dusk_exclusive(v) 	- returns 1 while not in dusk

		- __IntD(x, y, e) - "Interpolate Day" 
		sin function of the sun angle, to interpolate between:
		x (value when sunangle is 0°) and y (value when sun is 90°)
		e is the exponent of the sin function a = sin(sunangle)^e
		For example __IntD(0, 1, 0.5), will return almost 1 till the sun is realy near the horizon

        - __IntN(x, y, e) - "Interpolate Night"
        The same function as __IntD, but for night. You need to reverse the exponent, So __IntD(0, 1, 100) is a very steep curve 

		E.g.
		"Boost PP Brightness in the night"

		1. Method:
		ac.setPpBrightness( 1.14 * day_compensate(1.1) )

		Brightness will then be 1.14 at day and 1.24 at night


		2. Method (using math.lerp):
		ac.setPpBrightness( math.lerp( 1.24, 1.14, day_compensate(0) ) )
    ]]
    




   

    