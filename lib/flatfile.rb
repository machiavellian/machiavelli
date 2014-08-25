class Flatfile < Store
	def initialize origin, settings
		super
		@file      = mandatory_param :file_name, "store_settings"
		@metric    = mandatory_param :metric, "store_settings"
		@delimiter = optional_param  :delimiter, ",", "store_settings"

		@base_url  = @file #synonym for is_up error msg
	end

	def test_file
		raise Store::Error, "Error: file #{@file} does not exist" unless is_up?
	end

	def is_up?
		File.exists?(@file)
	end

	def live?
		false # Flat files don't auto update, therefore cannot be assumed to be live
	end

	def metadata str
		str
	end

	def get_metrics_list
		test_file
		[@metric]	
        end

	def get_metric_url m, start,stop,step
		 return "file://#{Rails.root}/#{@file}"

	end

        def get_metric m, start=nil, stop=nil, step=nil
		test_file
		
		data = []
		File.open(@file).each_line do |line|
			x, y = line.split(@delimiter)
			data << {x: x.to_i, y: y.to_f} if x.to_i.between?(start, stop)
		end

		raise Store::Error, "No data for #{m} within selected time period" if data == []

		filtered = []			
		
		# Attempt filtering of data as per the 3st parameters.
		(start..stop).step(step).each do |x|
			points = data.select{|p| p[:x].between?(x, x+step-1)}
			case
				when points.length == 1 then 
					filtered << {x: x, y: points[0][:y]}
				when points.length > 0 then 
					avg = points.map{|b| b[:y]}.inject{|a, b| a+b}.to_f / points.size
					filtered << {x: x, y: avg}
				when points.length == 0 then
					# no data within range, so give it a NaN
					filtered << {x: x, y: (0.0 / 0.0)}
			end
		end
		point_c = (stop - start) / step
		filtered.take(point_c)
        end
end 
