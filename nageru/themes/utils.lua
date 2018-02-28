-- Utility function to help creating many similar chains that can differ
-- in a free set of chosen parameters.
function make_cartesian_product(parms, callback)
	return make_cartesian_product_internal(parms, callback, 1, {})
end

function make_cartesian_product_internal(parms, callback, index, args)
	if index > #parms then
		return callback(unpack(args))
	end
	local ret = {}
	for _, value in ipairs(parms[index]) do
		args[index] = value
		ret[value] = make_cartesian_product_internal(parms, callback, index + 1, args)
	end
	return ret
end


function make_sbs_input(chain, signal, deint, hq)
	local input = chain:add_live_input(not deint, deint)  -- Override bounce only if not deinterlacing.
	input:connect_signal(signal)

	local resample_effect = nil
	local resize_effect = nil
	if (hq) then
		resample_effect = chain:add_effect(ResampleEffect.new())
	else
		resize_effect = chain:add_effect(ResizeEffect.new())
	end
	local wb_effect = chain:add_effect(WhiteBalanceEffect.new())

	local padding_effect = chain:add_effect(IntegralPaddingEffect.new())

	return {
		input = input,
		wb_effect = wb_effect,
		resample_effect = resample_effect,
		resize_effect = resize_effect,
		padding_effect = padding_effect
	}
end

-- The main live chain.
function make_sbs_chain(input0_signal, input0_type, input1_signal, input1_type, hq)
	local chain = EffectChain.new(16, 9)

	local input0 = make_sbs_input(chain, input0_signal, input0_type == "livedeint", hq)
	local input1 = make_sbs_input(chain, input1_signal, input1_type == "livedeint", hq)

	local sbs = chain:add_effect(OverlayEffect.new(), input0.padding_effect, input1.padding_effect)

	local background = chain:add_effect(ImageInput.new("./images/placeholder.png"))
	chain:add_effect(OverlayEffect.new(), background, sbs)

	chain:finalize(hq)

	return {
		chain = chain,
		input0 = input0,
		input1 = input1
	}
end

function make_fade_input(chain, signal, live, deint, scale)
	local input, wb_effect, resample_effect, last
	if live then
		input = chain:add_live_input(false, deint)
		input:connect_signal(signal)
		last = input
	else
		input = chain:add_effect(ImageInput.new("./images/static.png"))
		last = input
	end

	-- If we cared about this for the non-main inputs, we would have
	-- checked hq here and invoked ResizeEffect instead.
	if scale then
		resample_effect = chain:add_effect(ResampleEffect.new())
		last = resample_effect
	end

	-- Make sure to put the white balance after the scaling (usually more efficient).
	if live then
		wb_effect = chain:add_effect(WhiteBalanceEffect.new())
		last = wb_effect
	end

	return {
		input = input,
		wb_effect = wb_effect,
		resample_effect = resample_effect,
		last = last
	}
end

-- A chain to fade between two inputs, of which either can be a picture
-- or a live input. In practice only used live, but we still support the
-- hq parameter.
function make_fade_chain(input0_signal, input0_live, input0_deint, input0_scale, input1_signal, input1_live, input1_deint, input1_scale, hq)
	local chain = EffectChain.new(16, 9)

	local input0 = make_fade_input(chain, input0_signal, input0_live, input0_deint, input0_scale)
	local input1 = make_fade_input(chain, input1_signal, input1_live, input1_deint, input1_scale)

	local mix_effect = chain:add_effect(MixEffect.new(), input0.last, input1.last)
	chain:finalize(hq)

	return {
		chain = chain,
		input0 = input0,
		input1 = input1,
		mix_effect = mix_effect
	}
end

-- A chain to show a single input on screen.
function make_simple_chain(input_deint, input_scale, hq)
	local chain = EffectChain.new(16, 9)

	local input = chain:add_live_input(false, input_deint)
	input:connect_signal(0)  -- First input card. Can be changed whenever you want.

	local resample_effect, resize_effect
	if scale then
		if hq then
			resample_effect = chain:add_effect(ResampleEffect.new())
		else
			resize_effect = chain:add_effect(ResizeEffect.new())
		end
	end

	local wb_effect = chain:add_effect(WhiteBalanceEffect.new())
	chain:finalize(hq)

	return {
		chain = chain,
		input = input,
		wb_effect = wb_effect,
		resample_effect = resample_effect,
		resize_effect = resize_effect
	}
end


function set_scale_parameters_if_needed(chain_or_input, width, height)
	if chain_or_input.resample_effect then
		chain_or_input.resample_effect:set_int("width", width)
		chain_or_input.resample_effect:set_int("height", height)
	elseif chain_or_input.resize_effect then
		chain_or_input.resize_effect:set_int("width", width)
		chain_or_input.resize_effect:set_int("height", height)
	end
end


-- Helper function to write e.g. “720p60”. The difference between this
-- and get_channel_resolution_raw() is that this one also can say that
-- there's no signal.
function get_channel_resolution(res)
	if (not res) or not res.is_connected then
		return "disconnected"
	end
	if res.height <= 0 then
		return "no signal"
	end
	if not res.has_signal then
		if res.height == 525 then
			-- Special mode for the USB3 cards.
			return "no signal"
		end
		return get_channel_resolution_raw(res) .. ", no signal"
	else
		return get_channel_resolution_raw(res)
	end
end

-- Helper function to write e.g. “60” or “59.94”.
function get_frame_rate(res)
	local nom = res.frame_rate_nom
	local den = res.frame_rate_den
	if nom % den == 0 then
		return nom / den
	else
		return string.format("%.2f", nom / den)
	end
end

-- Helper function to write e.g. “720p60”.
function get_channel_resolution_raw(res)
	if res.interlaced then
		return res.height .. "i" .. get_frame_rate(res)
	else
		return res.height .. "p" .. get_frame_rate(res)
	end
end


function place_rectangle(resample_effect, resize_effect, padding_effect, x0, y0, x1, y1, screen_width, screen_height, input_width, input_height)
	local srcx0 = 0.0
	local srcx1 = 1.0
	local srcy0 = 0.0
	local srcy1 = 1.0

	padding_effect:set_int("width", screen_width)
	padding_effect:set_int("height", screen_height)

	-- Cull.
	if x0 > screen_width or x1 < 0.0 or y0 > screen_height or y1 < 0.0 then
		if resample_effect ~= nil then
			resample_effect:set_int("width", 1)
			resample_effect:set_int("height", 1)
			resample_effect:set_float("zoom_x", screen_width)
			resample_effect:set_float("zoom_y", screen_height)
		else
			resize_effect:set_int("width", 1)
			resize_effect:set_int("height", 1)
		end
		padding_effect:set_int("left", screen_width + 100)
		padding_effect:set_int("top", screen_height + 100)
		return
	end

	local width = math.ceil(x1 - x0)
	local height = math.ceil(y1 - y0)
	local distorsion = (width * screen_height) - (screen_width * height)
	local aspect_factor = (width / height) / (screen_width / screen_height)

	if distorsion < -1000 then
		-- Vertical crop
		crop = (screen_width - (width * screen_height / height)) / 2
		srcx0 = crop / (screen_width)
		srcx1 = 1 - (crop / (screen_width))
	elseif distorsion > 1000 then
		-- Horizontal crop
		crop = (screen_height - (height * screen_width / width)) / 2
		srcy0 = crop / (screen_height)
		srcy1 = 1 - (crop / (screen_height))
	end

	-- Clip.
	if x0 < 0 then
		srcx0 = (-x0 / (x1 - x0)) * aspect_factor + srcx0
		x0 = 0
	end
	if y0 < 0 then
		srcy0 = (-y0 / (y1 - y0)) * aspect_factor + srcy0
		y0 = 0
	end
	if x1 > screen_width then
		srcx1 = (screen_width - x0) / (x1 - x0)
		x1 = screen_width
	end
	if y1 > screen_height then
		srcy1 = (screen_height - y0) / (y1 - y0)
		y1 = screen_height
	end

	if resample_effect ~= nil then
		-- High-quality resampling.
		local x_subpixel_offset = x0 - math.floor(x0)
		local y_subpixel_offset = y0 - math.floor(y0)
	
		-- Resampling must be to an integral number of pixels. Round up,
		-- and then add an extra pixel so we have some leeway for the border.
		resample_effect:set_int("width", width)
		resample_effect:set_int("height", height)

		-- Correct the discrepancy with zoom. (This will leave a small
		-- excess edge of pixels and subpixels, which we'll correct for soon.)
		local zoom_x = (x1 - x0) / (width * (srcx1 - srcx0))
		local zoom_y = (y1 - y0) / (height * (srcy1 - srcy0))
		resample_effect:set_float("zoom_x", zoom_x)
		resample_effect:set_float("zoom_y", zoom_y)
		resample_effect:set_float("zoom_center_x", 0.0)
		resample_effect:set_float("zoom_center_y", 0.0)

		-- Padding must also be to a whole-pixel offset.
		padding_effect:set_int("left", math.floor(x0))
		padding_effect:set_int("top", math.floor(y0))

		-- Correct _that_ discrepancy by subpixel offset in the resampling.
		resample_effect:set_float("left", srcx0 * input_width - x_subpixel_offset / zoom_x)
		resample_effect:set_float("top", srcy0 * input_height - y_subpixel_offset / zoom_y)

		-- Finally, adjust the border so it is exactly where we want it.
		padding_effect:set_float("border_offset_left", x_subpixel_offset)
		padding_effect:set_float("border_offset_right", x1 - (math.floor(x0) + width))
		padding_effect:set_float("border_offset_top", y_subpixel_offset)
		padding_effect:set_float("border_offset_bottom", y1 - (math.floor(y0) + height))
	else
		-- Lower-quality simple resizing.
		resize_effect:set_int("width", width)
		resize_effect:set_int("height", height)

		-- Padding must also be to a whole-pixel offset.
		padding_effect:set_int("left", math.floor(x0))
		padding_effect:set_int("top", math.floor(y0))
	end
end

-- This is broken, of course (even for positive numbers), but Lua doesn't give us access to real rounding.
function round(x)
	return math.floor(x + 0.5)
end

function lerp(a, b, t)
	return a + (b - a) * t
end

function lerp_pos(a, b, t)
	return {
		x0 = lerp(a.x0, b.x0, t),
		y0 = lerp(a.y0, b.y0, t),
		x1 = lerp(a.x1, b.x1, t),
		y1 = lerp(a.y1, b.y1, t)
	}
end

function pos_from_top_left(x, y, width, height, screen_width, screen_height)
	local xs = screen_width / 1280.0
	local ys = screen_height / 720.0
	return {
		x0 = round(xs * x),
		y0 = round(ys * y),
		x1 = round(xs * (x + width)),
		y1 = round(ys * (y + height))
	}
end

-- Find the transformation that changes the first rectangle to the second one.
function find_affine_param(a, b)
	local sx = (b.x1 - b.x0) / (a.x1 - a.x0)
	local sy = (b.y1 - b.y0) / (a.y1 - a.y0)
	return {
		sx = sx,
		sy = sy,
		tx = b.x0 - a.x0 * sx,
		ty = b.y0 - a.y0 * sy
	}
end

function place_rectangle_with_affine(resample_effect, resize_effect, padding_effect, pos, aff, screen_width, screen_height, input_width, input_height)
	local x0 = pos.x0 * aff.sx + aff.tx
	local x1 = pos.x1 * aff.sx + aff.tx
	local y0 = pos.y0 * aff.sy + aff.ty
	local y1 = pos.y1 * aff.sy + aff.ty

	place_rectangle(resample_effect, resize_effect, padding_effect, x0, y0, x1, y1, screen_width, screen_height, input_width, input_height)
end

function set_neutral_color(effect, color)
	effect:set_vec3("neutral_color", color[1], color[2], color[3])
end

function calc_fade_progress(t, transition_start, transition_end)
	local tt = (t - transition_start) / (transition_end - transition_start)
	if tt < 0.0 then
		return 0.0
	elseif tt > 1.0 then
		return 1.0
	end

	-- Make the fade look maybe a tad more natural, by pumping it
	-- through a sigmoid function.
	tt = 10.0 * tt - 5.0
	tt = 1.0 / (1.0 + math.exp(-tt))

	return tt
end

function bytes_to_int(str) -- use length of string to determine 8,16,32,64 bits
	local t={str:byte(1,-1)}

	--bigendian
	local n=0
	for k=1, #t do
		n=n+t[k]*2^((#t-k)*8)
	end
	return n
end

function parse_osc_msg(msg)
	-- each OSC string is padded with \0 to be a 4 multiple
	-- each OSC message have the following structure :
	-- * path (OSC string)
	-- * ,t where t is the type of the value (s, i...) - OSC String
	-- * the value

	-- see http://opensoundcontrol.org/spec-1_0 for protocol spec
	-- and http://opensoundcontrol.org/spec-1_0-examples for examples

	local comma = string.find(msg, ",")

	if not comma then
		return
	end

	-- extract address until the first \0
	local address = string.sub(msg, 0, string.find(msg, "\0") - 1)

	-- extract value type between , and first \0
	local oscType = string.sub(msg, comma + 1, string.find(msg, "\0", comma + 1) - 1)
	local value

	if (oscType == "s") then
		value = string.sub(msg, comma + 4, string.find(msg, "\0", comma+4) - 1)
	end

	if (oscType == "i") then
		oscInt = string.sub(msg, comma +4, comma + 8)
		value = bytes_to_int(oscInt)
	end

	return address, value

end