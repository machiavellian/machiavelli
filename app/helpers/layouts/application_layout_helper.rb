require 'cgi'
require 'uri'

module Layouts
	module ApplicationLayoutHelper
		UI_DEFAULTS = {	
			start: "3h",
			graph: "standard"
		}
		
		def ui_message msg
			case msg
			when :no_graphs_selected; "Select a metric from the list to graph"
			when :no_metrics_available; "No metrics available. Check error notification, or #{link_to "refresh", refresh_path} to try again.".html_safe
			when :no_backends; "No backends configured. Check your config/settings/{ENV}.yml file."
			else "UI MESSAGE VARIABLE NOT FOUND: #{msg}"
			end
		end
			
		def flash_class(level)
		    case level
			when :notice  then "alert alert-info"
			when :success then "alert alert-success"
			when :error   then "alert alert-danger"
			when :warning then "alert alert-warning"
		    end
		end

		# Safety First - very basic javascript compatible variable name changer
		def safe_string s	
			s.tr("/.:-","_")
		end


		def render_sidenav
			render(partial: "partial/sidenav/filter_metrics")
		end

		def navbar_buttons param, buttons
			a = []
			buttons.each do |b|
				html = "<a type='button' class='btn btn-xs btn-default "
				p = chk_qs(param,b) 

				html += "active" if (p || p.nil? && UI_DEFAULTS[param] == b)
				html += "' href='"+ chg_qs(param, b) +"'>"+b+"</a>"
				a << html
			end
			a
		end

		# Query string manipulation functions
		def chk_qs k,v,p={}; alter_qs :chk, k,v,p; end
		def chg_qs k,v,p={}; alter_qs :chg, k,v,p; end
		def add_qs k,v,p={}; alter_qs :add, k,v,p; end
		def rem_qs k,v,p={}; alter_qs :rem, k,v,p; end

		def query_hash p={}
			url = (p[:url] == :referer ? request.referer : request.url)

			query = URI::parse(url).query
                        query.gsub!("metric=","metric[]=") if query

                        Rack::Utils.parse_nested_query(query) || {} 
		end

		def hash_query hash
			x = []
                        hash.each {|l,m| Array(m).each {|a| x << "#{l}=#{a}"}}
                        "?#{x.join("&")}"
		end

		def alter_qs method, k, v, p={}
			k = k.to_s
			hash = query_hash p
		
			case method
				when :chk
					return (hash[k] ? (hash[k] == v ? true : false) : nil)
				when :add
					if v.is_a? Array 
						hash[k] ? hash[k] += v : hash[k] = v
					else
						hash[k] ? hash[k] << v : hash[k] = v
					end
				when :chg
					hash[k] = v
					hash.delete("metric") if k == "backend"
				when :rem
					x = Array(hash[k])
					x.delete(v)
					x.empty? ? hash.delete(k) : hash[k] = x
			end
			
			hash_query hash
		end

	end
end
