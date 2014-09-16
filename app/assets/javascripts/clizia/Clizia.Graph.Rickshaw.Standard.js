Clizia.Graph.Rickshaw.Standard = function(args) { 
	var that = Clizia.Graph.Rickshaw(args);

	that.render = function(args) { 
		$.getJSON(that.feed(), function(data) { 
			if (that.invalidData(data)) { 
				err = data.error ||  errorMessage.noData	
				renderError(that.chart, err, null, that.metric.removeURL)
				throw "Error retrieving data: "+err
			}

			graph = new Rickshaw.Graph({
				element: document.getElementById(that.chart),
				width: that.width, 
				height: that.height,
				renderer: 'line', 
				series: [{ data: data, color: that.metric.color }]
			});
			
			that.graph = graph;
			extent = that.extents(data);

			graph.configure({min: extent[0] - that.padding, max: extent[1] + that.padding});

			if (that.metric.counter)  { 
				graph.configure({interpolation: 'step'});
			}

			new Rickshaw.Graph.Axis.Y( {
				graph: graph,
				orientation: 'left',
				interpolate: 'monotone',
				pixelsPerTick: 30,
				tickFormat: Rickshaw.Fixtures.Number.formatKMBT_round,
				element: document.getElementById(that.yaxis)
			} );

			new Rickshaw.Graph.Axis.Time({
				graph: graph,
				timeFixture: that.timeFixture()
			});

			that.dynamicWidth();
			graph.render();
			
			new Rickshaw.Graph.HoverDetail({
				graph: graph,
				formatter: function (series, x, y) {
					content = "<span class='date'>" + 
						  that.d3_time(x) +
						  "</span><br/>" + 
						  that.format(y);
					return content;
				}
			});

			graph.render();	


			if (that.slider) { 
				that.slider.render({graphs: graph})
			} 

			if (that.showurl) {
				Clizia.Utils.showURL(that.showurl, that.metric.sourceURL);
			} 

			if (that.removeurl) { 
				Clizia.Utils.removeURL(that.removeurl, that.metric.removeURL);
			} 
		})
	} 

	return that;
}

