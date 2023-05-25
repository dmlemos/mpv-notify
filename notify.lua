-- notify.lua -- Desktop notifications for mpv.
-- Just put this file into your ~/.config/mpv/scripts folder and mpv will find it.
--
-- Copyright (c) 2014 Roland Hieber
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

NOTIFICATION_TIMEOUT = 4 --seconds

-------------------------------------------------------------------------------
-- helper functions
-------------------------------------------------------------------------------
function print_debug(s)
	print("DEBUG: " .. s) -- comment out for no debug info
	return true
end

-- escape string for shell inclusion
function string.shellescape(str)
	return "'"..string.gsub(str, "'", "'\"'\"'").."'"
end

-- converts string to a valid filename on most (modern) filesystems
function string.safe_filename(str)
	local s, _ = string.gsub(str, "([^A-Za-z0-9_.-])",
		function(c)
			return ("%02x"):format(c:byte())
		end)
	return s;
end

-- check if a file exists and is readable
function file_exists(name)
	local f=io.open(name, "r")
	if f~=nil then io.close(f) return true else return false end
end

-------------------------------------------------------------------------------
-- main
-------------------------------------------------------------------------------
-- scale an image file
-- @return boolean of success
function scaled_image(src, dst)
	local convert_cmd = ("convert -scale x64 -- %s %s"):format(
		string.shellescape(src), string.shellescape(dst))
	-- print_debug("executing " .. convert_cmd)
	if os.execute(convert_cmd) then
		return true
	end
	return false
end

-- extract image from audio file
function extracted_image_from_audiofile (audiofile, imagedst)
  local ffmpeg_cmd = ("ffmpeg -loglevel -8 -vsync 2 -i %s %s > /dev/null"):format(
    string.shellescape(audiofile), string.shellescape(imagedst)
  )
  -- print_debug("executing " .. ffmpeg_cmd)
  if os.execute(ffmpeg_cmd) then
    return true
  end
  return false
end

function get_value(data, keys)
	for _,v in pairs(keys) do
		if data[v] and string.len(data[v]) > 0 then
			return data[v]
		end
	end
	return ""
end

-- array with all the arguments escaped
function make_args(arr, arg1, arg2)
	table.insert(arr, arg1)
	table.insert(arr, string.shellescape(arg2))
end


COVER_ART_PATH = "/tmp/cover_art.jpg"
ICON_PATH = "/tmp/icon.jpg"

function notify_current_track()
	-- skip when mp data is not available yet (e.g. when loading a playlist) or it is not an audio file
	-- print_debug("track-list/count: " .. mp.get_property_native("track-list/count"))
	if mp.get_property_native("track-list/count") < 1 or mp.get_property_native("video-format") then
		return
	end

	TITLE_STR = "Now playing: "
	params = {}

	-- print_debug("metadata count: " .. mp.get_property_native("metadata/list/count"))
	if mp.get_property_native("metadata/list/count") > 0 then
		os.remove(COVER_ART_PATH)
		os.remove(ICON_PATH)

		metadata = mp.get_property_native("metadata")

		-- try to fetch metadata values using all possible keys
		track_artist = get_value(metadata, {"artist", "ARTIST", "album_artist"})
		track_album  = get_value(metadata, {"album", "ALBUM"})
		track_title  = get_value(metadata, {"title", "TITLE", "icy-title"})

		-- print_debug("notify_current_track(): -> extracted metadata:")
		-- print_debug("artist: " .. track_artist)
		-- print_debug("album: " .. track_album)
		-- print_debug("title: " .. track_title)

		if string.len(track_artist) > 0 then
			make_args(params, "-title", TITLE_STR .. track_artist)
		end

		if string.len(track_album) > 0 then
			make_args(params, "-subtitle", track_album .. " [ALBUM]")
		end

		if string.len(track_title) > 0 then
			make_args(params, "-message", track_title .. " [TITLE]")
		end

		-- absolute filename of currently playing audio file
		local abs_filename = mp.get_property_native("path")
		if not abs_filename:match("^%/") then
			abs_filename = os.getenv("PWD") .. "/" .. abs_filename
		end
		-- extract cover art: set it as icon in notification params
		if extracted_image_from_audiofile(abs_filename, COVER_ART_PATH) then
			if file_exists(COVER_ART_PATH) and scaled_image(COVER_ART_PATH, ICON_PATH) then
				make_args(params, "-contentImage", ICON_PATH)
			end
		end
	else
		-- when metadata is not available, use the filename
		make_args(params, "-title", TITLE_STR)
		make_args(params, "-message", mp.get_property_native("filename/no-ext"))
	end

	local command = ("alerter -ignoreDnD -timeout %s %s > /dev/null &"):format(NOTIFICATION_TIMEOUT, table.concat(params, ' '))
	-- print_debug("command: " .. command)
	os.execute(command)
end

function notify_pause_updated(name, value)
	if value == false then
		notify_current_track()
	-- -- uncomment to notify on pause
	-- else
	-- 	local command = ("alerter -ignoreDnD -timeout % -title 'mpv' -message 'Music Paused' > /dev/null &"):format(NOTIFICATION_TIMEOUT)
	-- 	print_debug("command: " .. command)
	-- 	os.execute(command)
	end
end


mp.register_event("file-loaded", notify_current_track)
mp.observe_property("pause", "bool", notify_pause_updated)
