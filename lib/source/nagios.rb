# Collector: https://github.com/anchor/vaultaire-collector-nagios
class Source::Nagios < Source::Source
	include Helpers

	# Humanize the title for the perfdata feed. Handles both v1 and v2 style Vaultaire metadata
	def titleize keys 
		nice = []

		if keys.include? "hostname"
			nice << keys["hostname"]
			nice << keys["service_name"] unless keys["service_name"] == "host"
			nice << keys["metric"]
		else
			nice << keys["host"]
			nice << keys["service"] unless keys["service"] == "host"
			nice << keys["metric"]
		end

		return URI.decode(nice.join(" - "))
	end

	# For nagios, add some nice things
	def metaadd meta
		if meta["service"] == "cpu" then
			color = { "Idle" => "#dddddd",  # an "idle" color
	   			"User" => "#3465a4", "System" => "#73d216", "Nice" => "#f57900", "Iowait" => "#cc0000", #pnp4nagios
				"Irq" => "#916f7c", "Softirq" => "#9955ff" , "Steal" => "#ffcc00" # fill the remaining palette

			}
		elsif meta["service"] == "mem" then
			color = { "Used" => "#729fcf", "Cached" => "#fcaf3e", "Buffers" => "#fce84f", "Free" => "#8ae234"} #pnp4nagios
		elsif meta["service"] == "neutron-L3_agents" then
			color = { "l3_agents_alive" => "#54CA05", "l3_agents_dead" => "#2A6403", "routers_dead" => "#ff0000", "routers_alive" => "#ffeb00"}
		end

		color.each{|k,v| if meta["metric"].include? k then meta["color"] = v; end } if color

		return meta
	end
end
