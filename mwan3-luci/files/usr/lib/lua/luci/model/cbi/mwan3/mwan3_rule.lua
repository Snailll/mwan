-- ------ extra functions ------ --

function rulelist()
	uci.cursor():foreach("mwan3", "rule",
		function (section)
			local sport = ut.trim(sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".src_port"))
			local dport = ut.trim(sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".dest_port"))
			if sport ~= "" or dport ~= "" then
				local proto = ut.trim(sys.exec("uci get -p /var/state mwan3." .. section[".name"] .. ".proto"))
				if proto == "all" or proto == "" then
					rulestr = rulestr .. section[".name"] .. " "
					protofix = 1
				end
			end
		end
	)
end

function rulewarn()
	warns = "<strong><em>Sorting of rules affects MWAN3! Rules are read from top to bottom</em></strong>"
	if protofix == 1 then
		warns = warns .. "<br /><br /><font color=\"ff0000\"><strong><em>WARNING: some rules have port(s) configured and no protocol specified! Please configure a specific protocol!</em></strong></font>"
	end
	return warns
end

-- ------ rule configuration ------ --

dsp = require "luci.dispatcher"
sys = require "luci.sys"
ut = require "luci.util"

protofix = 0
rulestr = ""
rulelist()


m5 = Map("mwan3", translate("MWAN3 Multi-WAN traffic Rule Configuration"),
	translate(rulewarn()))


mwan_rule = m5:section(TypedSection, "rule", translate("Traffic Rules"),
	translate("MWAN3 supports an unlimited number of rules<br />" ..
	"Name may contain characters A-Z, a-z, 0-9, _ and no spaces<br />" ..
	"Rules may not share the same name as configured interfaces, members or policies"))
	mwan_rule.addremove = true
	mwan_rule.anonymous = false
	mwan_rule.dynamic = false
	mwan_rule.sortable = true
	mwan_rule.template = "cbi/tblsection"
	mwan_rule.extedit = dsp.build_url("admin", "network", "mwan3", "rule", "%s")
	function mwan_rule.create(self, section)
		TypedSection.create(self, section)
		m5.uci:save("mwan3")
		luci.http.redirect(dsp.build_url("admin", "network", "mwan3", "rule", section))
	end


src_ip = mwan_rule:option(DummyValue, "src_ip", translate("Source address"))
	src_ip.rawhtml = true
	function src_ip.cfgvalue(self, s)
		return self.map:get(s, "src_ip") or "<br /><font size=\"+4\">-</font><br />"
	end

src_port = mwan_rule:option(DummyValue, "src_port", translate("Source port"))
	src_port.rawhtml = true
	function src_port.cfgvalue(self, s)
		return self.map:get(s, "src_port") or "<br /><font size=\"+4\">-</font>"
	end

dest_ip = mwan_rule:option(DummyValue, "dest_ip", translate("Destination address"))
	dest_ip.rawhtml = true
	function dest_ip.cfgvalue(self, s)
		return self.map:get(s, "dest_ip") or "<br /><font size=\"+4\">-</font>"
	end

dest_port = mwan_rule:option(DummyValue, "dest_port", translate("Destination port"))
	dest_port.rawhtml = true
	function dest_port.cfgvalue(self, s)
		return self.map:get(s, "dest_port") or "<br /><font size=\"+4\">-</font>"
	end

proto = mwan_rule:option(DummyValue, "proto", translate("Protocol"))
	proto.rawhtml = true
	function proto.cfgvalue(self, s)
		local protocol = self.map:get(s, "proto")
		if protofix == 0 then
			return protocol or "<br /><font size=\"+4\">-</font>"
		else
			if ut.trim(sys.exec("echo '" .. rulestr .. "' | grep -c '" .. s .. "'")) == "0" then
				return protocol or "<br /><font size=\"+4\">-</font>"
			else
				if protocol then
					return "<br /><font color=\"ff0000\">" .. protocol .. "</font>"
				else
					return "<br /><font color=\"ff0000\"><font size=\"+4\">-</font></font>"
				end
			end
		end
	end

use_policy = mwan_rule:option(DummyValue, "use_policy", translate("Policy assigned"))
	use_policy.rawhtml = true
	function use_policy.cfgvalue(self, s)
		local upol = self.map:get(s, "use_policy")
		if upol then
			if upol == "default" then
				return "default routing table"
			else
				return upol
			end
		else
			return "<br /><font size=\"+4\">-</font>"
		end
	end

equalize = mwan_rule:option(DummyValue, "equalize", translate("Equalize"))
	function equalize.cfgvalue(self, s)
		if self.map:get(s, "equalize") == "1" then
			return "Yes"
		else
			return "No"
		end
	end


return m5
