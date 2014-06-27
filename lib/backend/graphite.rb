# Required config/settings.yml > backend > settings parameters: 
#  url - the graphite instance url. 
require 'net/http'

# Here be graphite hackery
class Backend::Graphite < Backend::GenericBackend

	def initialize params={}
		@alias = params[:alias] || self.class.name.split("::").last
		@base_url = params[:url]
		raise Backend::Error, "Must provide a url value" if @base_url.nil?
	end

	def get_metrics_list
		begin
			get_json "#{@base_url}/metrics/index.json"
		rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
			raise Backend::Error, "Error retrieving Graphite metrics list: #{e}"
		end
	end

	def get_metric m, start=nil, stop=nil, step=nil, args={}
		url = 	@base_url + 
			"/render?target=" + m + 
			"&from=#{start}" +
			"&until=#{stop}" +
			"&format=json"

		# Because why cook when you can create?
		url.gsub!(m, "summarize(#{m},'#{step}sec','avg')") if step

		if args[:return_url]
			return url
		end

		begin
			stats = get_json url
		rescue ArgumentError => e
			raise Backend::Error, "Graphite Exception raised: #{e}"
		rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
			raise Backend::Error, "Error retrieving Graphite metric #{m}: #{e}"
		end
	
		raise Backend::Error, "No data available for metric #{m}" if stats == []

		metric = []
		stats[0]["datapoints"].each do |node|
			#because Graphite does [value,epoch], instead of the more sane [epoch,value]
			metric << {x: node[1], y: node[0] } 
		end

		points = (stop - start)/step

		return metric.take(points)
	end

	def get_json url
		uri = URI.parse(url)

		http = Net::HTTP.new(uri.host, uri.port)

		if uri.is_a? URI::HTTPS then
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		end

		result = http.get uri.request_uri

		# Because asking for json return html if there's an error. 
		if result.body.include? "Exception"
			raise ArgumentError, result.body.split("\n").select{|i| i[/^Exception/]}.join("\n").gsub("&#39;","'")
		end
		
		JSON.parse(result.body)
	end
end
