--
-- In order to respond to OSC message, you must install lua-socket
--

-- The theme is what decides what's actually shown on screen, what kind of
-- transitions are available (if any), and what kind of inputs there are,
-- if any. In general, it drives the entire display logic by creating Movit
-- chains, setting their parameters and then deciding which to show when.
--
-- Themes are written in Lua, which reflects a simplified form of the Movit API
-- where all the low-level details (such as texture formats) are handled by the
-- C++ side and you generally just build chains.

local transition_start = -2.0
local transition_end = -1.0
local transition_type = 0
local transition_src_signal = 0
local transition_dst_signal = 0

local neutral_colors = {
	{0.5, 0.5, 0.5},  -- Input 0.
	{0.5, 0.5, 0.5}   -- Input 1.
}

local live_signal_num = 0
local preview_signal_num = 1

-- Valid values for live_signal_num and preview_signal_num.
local INPUT0_SIGNAL_NUM = 0
local INPUT1_SIGNAL_NUM = 1
local SBS_SIGNAL_NUM = 2
local STATIC_SIGNAL_NUM = 3

-- Valid values for transition_type. (Cuts are done directly, so they need no entry.)
local NO_TRANSITION = 0
local ZOOM_TRANSITION = 1  -- Also for slides.
local FADE_TRANSITION = 2

-- Last width/height/frame rate for each channel, if we have it.
-- Note that unlike the values we get from Nageru, the resolution is per
-- frame and not per field, since we deinterlace.
local last_resolution = {}

require('utils')

local socket = require("socket")
udp = assert(socket.udp())
assert(udp:setsockname("127.0.0.1", 21547))
assert(udp:settimeout(0))


-- Make all possible combinations of side-by-side chains.
local sbs_chains = make_cartesian_product({
	{"live", "livedeint"},  -- input0_type
	{"live", "livedeint"},  -- input1_type
	{true, false}           -- hq
}, function(input0_type, input1_type, hq)
	return make_sbs_chain(INPUT0_SIGNAL_NUM, input0_type, INPUT1_SIGNAL_NUM, input1_type, hq)
end)

-- Chains to fade between two inputs, in various configurations.
local fade_chains = make_cartesian_product({
	{"static", "live", "livedeint"},  -- input0_type
	{true, false},                    -- input0_scale
	{"static", "live", "livedeint"},  -- input1_type
	{true, false},                    -- input1_scale
	{true}                            -- hq
}, function(input0_type, input0_scale, input1_type, input1_scale, hq)
	local input0_live = (input0_type ~= "static")
	local input1_live = (input1_type ~= "static")
	local input0_deint = (input0_type == "livedeint")
	local input1_deint = (input1_type == "livedeint")
	return make_fade_chain(INPUT0_SIGNAL_NUM, input0_live, input0_deint, input0_scale, INPUT1_SIGNAL_NUM, input1_live, input1_deint, input1_scale, hq)
end)

-- Make all possible combinations of single-input chains.
local simple_chains = make_cartesian_product({
	{"live", "livedeint"},  -- input_type
	{true, false},          -- input_scale
	{true, false}           -- hq
}, function(input_type, input_scale, hq)
	local input_deint = (input_type == "livedeint")
	return make_simple_chain(input_deint, input_scale, hq)
end)

-- A chain to show a single static picture on screen (HQ version).
local static_chain_hq = EffectChain.new(16, 9)
local static_chain_hq_input = static_chain_hq:add_effect(ImageInput.new("bg.jpeg"))
static_chain_hq:finalize(true)

-- A chain to show a single static picture on screen (LQ version).
local static_chain_lq = EffectChain.new(16, 9)
local static_chain_lq_input = static_chain_lq:add_effect(ImageInput.new("bg.jpeg"))
static_chain_lq:finalize(false)

-- Used for indexing into the tables of chains.
function get_input_type(signals, signal_num)
	if signal_num == STATIC_SIGNAL_NUM then
		return "static"
	elseif signals:get_interlaced(signal_num) then
		return "livedeint"
	else
		return "live"
	end
end

function is_plain_signal(num)
	return num == INPUT0_SIGNAL_NUM or num == INPUT1_SIGNAL_NUM
end

function needs_scale(signals, signal_num, width, height)
	if signal_num == STATIC_SIGNAL_NUM then
		-- We assume this is already correctly scaled at load time.
		return false
	end
	assert(is_plain_signal(signal_num))
	return (signals:get_width(signal_num) ~= width or signals:get_height(signal_num) ~= height)
end

-- API ENTRY POINT
-- Returns the number of outputs in addition to the live (0) and preview (1).
-- Called only once, at the start of the program.
function num_channels()
	return 4
end

-- API ENTRY POINT
-- Returns the name for each additional channel (starting from 2).
-- Called at the start of the program, and then each frame for live
-- channels in case they change resolution.
function channel_name(channel)
	local signal_num = channel - 2
	if is_plain_signal(signal_num) then
		return "Input " .. (signal_num + 1) .. " (" .. get_channel_resolution(last_resolution[signal_num]) .. ")"
	elseif signal_num == SBS_SIGNAL_NUM then
		return "Side-by-side"
	elseif signal_num == STATIC_SIGNAL_NUM then
		return "Static picture"
	end
end

-- API ENTRY POINT
-- Returns, given a channel number, which signal it corresponds to (starting from 0).
-- Should return -1 if the channel does not correspond to a simple signal.
-- (The information is used for whether right-click on the channel should bring up
-- an input selector or not.)
-- Called once for each channel, at the start of the program.
-- Will never be called for live (0) or preview (1).
function channel_signal(channel)
	if channel == 2 then
		return 0
	elseif channel == 3 then
		return 1
	else
		return -1
	end
end

-- API ENTRY POINT
-- Called every frame. Returns the color (if any) to paint around the given
-- channel. Returns a CSS color (typically to mark live and preview signals);
-- "transparent" is allowed.
-- Will never be called for live (0) or preview (1).
function channel_color(channel)
	if transition_type ~= NO_TRANSITION then
		if channel_involved_in(channel, transition_src_signal) or
				channel_involved_in(channel, transition_dst_signal) then
			return "#f00"
		end
	else
		if channel_involved_in(channel, live_signal_num) then
			return "#f00"
		end
	end
	if channel_involved_in(channel, preview_signal_num) then
		return "#0f0"
	end
	return "transparent"
end

function channel_involved_in(channel, signal_num)
	if is_plain_signal(signal_num) then
		return channel == (signal_num + 2)
	end
	if signal_num == SBS_SIGNAL_NUM then
		return (channel == 2 or channel == 3)
	end
	if signal_num == STATIC_SIGNAL_NUM then
		return (channel == 5)
	end
	return false
end

-- API ENTRY POINT
-- Returns if a given channel supports setting white balance (starting from 2).
-- Called only once for each channel, at the start of the program.
function supports_set_wb(channel)
	return is_plain_signal(channel - 2)
end

-- API ENTRY POINT
-- Gets called with a new gray point when the white balance is changing.
-- The color is in linear light (not sRGB gamma).
function set_wb(channel, red, green, blue)
	if is_plain_signal(channel - 2) then
		neutral_colors[channel - 2 + 1] = { red, green, blue }
	end
end

function finish_transitions(t)
	if transition_type ~= NO_TRANSITION and t >= transition_end then
		live_signal_num = transition_dst_signal
		transition_type = NO_TRANSITION
	end
end

function in_transition(t)
	return t >= transition_start and t <= transition_end
end

-- API ENTRY POINT
-- Called every frame.
function get_transitions(t)
	if in_transition(t) then
		-- Transition already in progress, the only thing we can do is really
		-- cut to the preview. (TODO: Make an “abort” and/or “finish”, too?)
		return {"Cut"}
	end

	finish_transitions(t)

	if live_signal_num == preview_signal_num then
		-- No transitions possible.
		return {}
	end

	if (is_plain_signal(live_signal_num) or live_signal_num == STATIC_SIGNAL_NUM) and
			(is_plain_signal(preview_signal_num) or preview_signal_num == STATIC_SIGNAL_NUM) then
		return {"Cut", "", "Fade"}
	end

	-- Various zooms.
	if live_signal_num == SBS_SIGNAL_NUM and is_plain_signal(preview_signal_num) then
		return {"Cut", "Zoom in"}
	elseif is_plain_signal(live_signal_num) and preview_signal_num == SBS_SIGNAL_NUM then
		return {"Cut", "Zoom out"}
	end

	return {"Cut"}
end

function swap_preview_live()
	local temp = live_signal_num
	live_signal_num = preview_signal_num
	preview_signal_num = temp
end

function start_transition(type_, t, duration)
	transition_start = t
	transition_end = t + duration
	transition_type = type_
	transition_src_signal = live_signal_num
	transition_dst_signal = preview_signal_num
	swap_preview_live()
end

-- API ENTRY POINT
-- Called when the user clicks a transition button.
function transition_clicked(num, t)
	if num == 0 then
		-- Cut.
		if in_transition(t) then
			-- Ongoing transition; finish it immediately before the cut.
			finish_transitions(transition_end)
		end

		swap_preview_live()
	elseif num == 1 then
		-- Zoom.
		finish_transitions(t)

		if live_signal_num == preview_signal_num then
			-- Nothing to do.
			return
		end

		if is_plain_signal(live_signal_num) and is_plain_signal(preview_signal_num) then
			-- We can't zoom between these. Just make a cut.
			io.write("Cutting from " .. live_signal_num .. " to " .. live_signal_num .. "\n")
			swap_preview_live()
			return
		end

		if (live_signal_num == SBS_SIGNAL_NUM and is_plain_signal(preview_signal_num)) or
				(preview_signal_num == SBS_SIGNAL_NUM and is_plain_signal(live_signal_num)) then
			start_transition(ZOOM_TRANSITION, t, 1.0)
		end
	elseif num == 2 then
		finish_transitions(t)

		-- Fade.
		if (live_signal_num ~= preview_signal_num) and
				(is_plain_signal(live_signal_num) or
						live_signal_num == STATIC_SIGNAL_NUM) and
				(is_plain_signal(preview_signal_num) or
						preview_signal_num == STATIC_SIGNAL_NUM) then
			start_transition(FADE_TRANSITION, t, 1.0)
		else
			-- Fades involving SBS are ignored (we have no chain for it).
		end
	end
end

-- API ENTRY POINT
function channel_clicked(num)
	preview_signal_num = num
end

function get_fade_chain(signals, t, width, height, input_resolution)
	local input0_type = get_input_type(signals, transition_src_signal)
	local input0_scale = needs_scale(signals, transition_src_signal, width, height)
	local input1_type = get_input_type(signals, transition_dst_signal)
	local input1_scale = needs_scale(signals, transition_dst_signal, width, height)
	local chain = fade_chains[input0_type][input0_scale][input1_type][input1_scale][true]
	prepare = function()
		if input0_type == "live" or input0_type == "livedeint" then
			chain.input0.input:connect_signal(transition_src_signal)
			set_neutral_color_from_signal(chain.input0.wb_effect, transition_src_signal)
		end
		set_scale_parameters_if_needed(chain.input0, width, height)
		if input1_type == "live" or input1_type == "livedeint" then
			chain.input1.input:connect_signal(transition_dst_signal)
			set_neutral_color_from_signal(chain.input1.wb_effect, transition_dst_signal)
		end
		set_scale_parameters_if_needed(chain.input1, width, height)
		local tt = calc_fade_progress(t, transition_start, transition_end)

		chain.mix_effect:set_float("strength_first", 1.0 - tt)
		chain.mix_effect:set_float("strength_second", tt)
	end
	return chain.chain, prepare
end

-- SBS code (live_signal_num == SBS_SIGNAL_NUM, or in a transition to/from it).
function get_sbs_chain(signals, t, width, height, input_resolution)
	local input0_type = get_input_type(signals, INPUT0_SIGNAL_NUM)
	local input1_type = get_input_type(signals, INPUT1_SIGNAL_NUM)
	return sbs_chains[input0_type][input1_type][true]
end

function read_osc_msg()
	local dgram, ip, port = udp:receivefrom()
	if not dgram then
		return
	end
	print("Received '" .. dgram .. "' from " .. ip .. ":" .. port)

	local address, value = parse_osc_msg(dgram)
	print("Received OSC address [" .. address .. "] with type [" .. oscType .. "] and value [" .. value .. "]")

	if (address == "/preview") then
		channel_clicked(value)
	elseif (address == "/transition") then
		transition_clicked(value, t)
	end
end

-- API ENTRY POINT
-- Called every frame. Get the chain for displaying at input <num>,
-- where 0 is live, 1 is preview, 2 is the first channel to display
-- in the bottom bar, and so on up to num_channels()+1. t is the
-- current time in seconds. width and height are the dimensions of
-- the output, although you can ignore them if you don't need them
-- (they're useful if you want to e.g. know what to resample by).
--
-- <signals> is basically an exposed InputState, which you can use to
-- query for information about the signals at the point of the current
-- frame. In particular, you can call get_width() and get_height()
-- for any signal number, and use that to e.g. assist in chain selection.
--
-- You should return two objects; the chain itself, and then a
-- function (taking no parameters) that is run just before rendering.
-- The function needs to call connect_signal on any inputs, so that
-- it gets updated video data for the given frame. (You are allowed
-- to switch which input your input is getting from between frames,
-- but not calling connect_signal results in undefined behavior.)
-- If you want to change any parameters in the chain, this is also
-- the right place.
--
-- NOTE: The chain returned must be finalized with the Y'CbCr flag
-- if and only if num==0.
function get_chain(num, t, width, height, signals)
	read_osc_msg()

	local input_resolution = {}
	for signal_num=0,1 do
		local res = {
			width = signals:get_width(signal_num),
			height = signals:get_height(signal_num),
			interlaced = signals:get_interlaced(signal_num),
			is_connected = signals:get_is_connected(signal_num),
			has_signal = signals:get_has_signal(signal_num),
			frame_rate_nom = signals:get_frame_rate_nom(signal_num),
			frame_rate_den = signals:get_frame_rate_den(signal_num)
		}

		if res.interlaced then
			-- Convert height from frame height to field height.
			-- (Needed for e.g. place_rectangle.)
			res.height = res.height * 2

			-- Show field rate instead of frame rate; really for cosmetics only
			-- (and actually contrary to EBU recommendations, although in line
			-- with typical user expectations).
			res.frame_rate_nom = res.frame_rate_nom * 2
		end

		input_resolution[signal_num] = res
	end
	last_resolution = input_resolution

	if num == 0 then  -- Live.
		finish_transitions(t)
		if transition_type == ZOOM_TRANSITION then
			-- Transition in or out of SBS.
			local chain = get_sbs_chain(signals, t, width, height, input_resolution)
			prepare = function()
				prepare_sbs_chain(chain, calc_zoom_progress(t), transition_type, transition_src_signal, transition_dst_signal, width, height, input_resolution)
			end
			return chain.chain, prepare
		elseif transition_type == NO_TRANSITION and live_signal_num == SBS_SIGNAL_NUM then
			-- Static SBS view.
			local chain = get_sbs_chain(signals, t, width, height, input_resolution)
			prepare = function()
				prepare_sbs_chain(chain, 0.0, NO_TRANSITION, 0, SBS_SIGNAL_NUM, width, height, input_resolution)
			end
			return chain.chain, prepare
		elseif transition_type == FADE_TRANSITION then
			return get_fade_chain(signals, t, width, height, input_resolution)
		elseif is_plain_signal(live_signal_num) then
			local input_type = get_input_type(signals, live_signal_num)
			local input_scale = needs_scale(signals, live_signal_num, width, height)
			local chain = simple_chains[input_type][input_scale][true]
			prepare = function()
				chain.input:connect_signal(live_signal_num)
				set_scale_parameters_if_needed(chain, width, height)
				set_neutral_color_from_signal(chain.wb_effect, live_signal_num)
			end
			return chain.chain, prepare
		elseif live_signal_num == STATIC_SIGNAL_NUM then  -- Static picture.
			prepare = function()
			end
			return static_chain_hq, prepare
		else
			assert(false)
		end
	end
	if num == 1 then  -- Preview.
		num = preview_signal_num + 2
	end

	-- Individual preview inputs.
	if is_plain_signal(num - 2) then
		local signal_num = num - 2
		local input_type = get_input_type(signals, signal_num)
		local input_scale = needs_scale(signals, signal_num, width, height)
		local chain = simple_chains[input_type][input_scale][false]
		prepare = function()
			chain.input:connect_signal(signal_num)
			set_scale_parameters_if_needed(chain, width, height)
			set_neutral_color(chain.wb_effect, neutral_colors[signal_num + 1])
		end
		return chain.chain, prepare
	end
	if num == SBS_SIGNAL_NUM + 2 then
		local input0_type = get_input_type(signals, INPUT0_SIGNAL_NUM)
		local input1_type = get_input_type(signals, INPUT1_SIGNAL_NUM)
		local chain = sbs_chains[input0_type][input1_type][false]
		prepare = function()
			prepare_sbs_chain(chain, 0.0, NO_TRANSITION, 0, SBS_SIGNAL_NUM, width, height, input_resolution)
		end
		return chain.chain, prepare
	end
	if num == STATIC_SIGNAL_NUM + 2 then
		prepare = function()
		end
		return static_chain_lq, prepare
	end
end


function prepare_sbs_chain(chain, t, transition_type, src_signal, dst_signal, screen_width, screen_height, input_resolution)
	chain.input0.input:connect_signal(0)
	chain.input1.input:connect_signal(1)
	set_neutral_color(chain.input0.wb_effect, neutral_colors[1])
	set_neutral_color(chain.input1.wb_effect, neutral_colors[2])

	-- First input is positioned (16,48) from top-left.
	-- Second input is positioned (16,48) from the bottom-right.
	local pos0 = pos_from_top_left(286, 720 - 651, 973, 547, screen_width, screen_height)
	local pos1 = pos_from_top_left(20, 720 - 651, 247, 413, screen_width, screen_height)

	local pos_fs = { x0 = 0, y0 = 0, x1 = screen_width, y1 = screen_height }
	local affine_param
	if transition_type == NO_TRANSITION then
		-- Static SBS view.
		affine_param = { sx = 1.0, sy = 1.0, tx = 0.0, ty = 0.0 }   -- Identity.
	else
		-- Zooming to/from SBS view into or out of a single view.
		assert(transition_type == ZOOM_TRANSITION)
		local signal, real_t
		if src_signal == SBS_SIGNAL_NUM then
			signal = dst_signal
			real_t = t
		else
			assert(dst_signal == SBS_SIGNAL_NUM)
			signal = src_signal
			real_t = 1.0 - t
		end

		if signal == INPUT0_SIGNAL_NUM then
			affine_param = find_affine_param(pos0, lerp_pos(pos0, pos_fs, real_t))
		elseif signal == INPUT1_SIGNAL_NUM then
			affine_param = find_affine_param(pos1, lerp_pos(pos1, pos_fs, real_t))
		end
	end

	-- NOTE: input_resolution is not 1-indexed, unlike usual Lua arrays.
	place_rectangle_with_affine(chain.input0.resample_effect, chain.input0.resize_effect, chain.input0.padding_effect, pos0, affine_param, screen_width, screen_height, input_resolution[0].width, input_resolution[0].height)
	place_rectangle_with_affine(chain.input1.resample_effect, chain.input1.resize_effect, chain.input1.padding_effect, pos1, affine_param, screen_width, screen_height, input_resolution[1].width, input_resolution[1].height)
end


function set_neutral_color_from_signal(effect, signal)
	if is_plain_signal(signal) then
		set_neutral_color(effect, neutral_colors[signal - INPUT0_SIGNAL_NUM + 1])
	end
end

function calc_zoom_progress(t)
	if t < transition_start then
		return 0.0
	elseif t > transition_end then
		return 1.0
	else
		local tt = (t - transition_start) / (transition_end - transition_start)
		-- Smooth it a bit.
		return math.sin(tt * 3.14159265358 * 0.5)
	end
end
