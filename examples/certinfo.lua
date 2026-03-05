#!/usr/bin/env lua5.4
-- original C version: https://curl.se/libcurl/c/certinfo.html

local curl = require("curl")
local easy = curl.easy()

-- read writerCallback() to understand how this lua function is called
local function write_cb(userdata, data_buffer)
	print("[lua] write callback")
	userdata.data = userdata.data .. data_buffer
	userdata.count = userdata.count + #data_buffer
	return #data_buffer
end

local userdata = {
	data = "",
	count = 0,
}

-- easy:setopt(curl.OPT_URL, "https://www.example.com/")
easy:setopt(curl.OPT_URL, "https://www.example.com/")

-- track references of curlT.wud
easy:setopt(curl.OPT_WRITEDATA, userdata)
easy:setopt(curl.OPT_WRITEFUNCTION, write_cb)

-- C_OPT(SSL_VERIFYPEER, boolean)
-- C_OPT(SSL_VERIFYHOST, number)
easy:setopt(curl.OPT_SSL_VERIFYPEER, false)
easy:setopt(curl.OPT_SSL_VERIFYHOST, 0)

-- C_OPT(VERBOSE, boolean)
easy:setopt(curl.OPT_VERBOSE, false)
-- add C_OPT(CERTINFO, boolean) into ALL_CURL_OPT, so luacurl bind the constant and handle the setopt call
easy:setopt(curl.OPT_CERTINFO, true)

-- see how lcurl_easy_perform() returns errors
local ok, err, code = easy:perform()
if ok then
	print("[lua] transfer performed without error")

	-- see lcurl_easy_getinfo()
	-- this is a list, since CURLINFO_CERTINFO > CURLINFO_SLIST
	local certs = easy:getinfo(curl.INFO_CERTINFO)
	print(string.format("%d certs!", #certs))
	for _, cert in ipairs(certs) do
		for _, line in ipairs(cert) do
			io.write(line)
		end
		io.write('\n')
	end
else
	print("[lua] curl error code", code)
	print("[lua] string error message", err)
end

-- final dump

print("[lua] dump of received data")
print("[lua] number of received bytes", userdata.count)
print("[lua] received data as a string")
io.write(userdata.data)

-- clean up
-- we can also wait __gc to kick in, which is bind to the C function lcurl_easy_gc()
easy:cleanup()
