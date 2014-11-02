if $('#dashboard_realtime_container').length
  data = []
  @avg_data = []
  totalPoints = 300
  options =
    series:
      shadowSize: 1

    lines:
      show: true
      lineWidth: 0.5
      fill: true
      fillColor:
        colors: [
          opacity: 0.1
        ,
          opacity: 1
        ]

    yaxis:
      min: 0
      max: 0

    xaxis:
      show: false

    colors: ["#6ef146"]
    grid:
      tickColor: "#a8a3a3"
      borderWidth: 0

  chartData = (impressions) ->
    data = data.slice(1)  if data.length > 0

    # do a random walk
    while data.length < totalPoints
      prev = (if data.length > 0 then data[data.length - 1] else 50)
      if(localStorage.lastImpression != undefined and localStorage.lastImpression != null)
        y = (impressions - localStorage.lastImpression) / 2
      else
        y = 0
      y = 0  if y < 0
      data.push y

    # zip the generated y values with the x values
    res = []
    i = 0
    while i < data.length
      res.push [i, data[i]]
      ++i
    localStorage.lastImpression = impressions
    res

  $.get '/dashboard/realtime', {}, (data) ->
    plot = $.plot($("#chart_4"), [{label: 'Impressions', data: chartData(0)}], options)
    avg_data.push(parseInt(data.impressions.replace(/,/g,'')))
    setInterval ->
      $.get '/dashboard/realtime', {}, (data)->
        if(avg_data.length < 5)
          avg_data.push(parseInt(data.impressions.replace(/,/g,'')))
        else
          avg_data.shift()
          avg_data.push(parseInt(data.impressions.replace(/,/g,'')))

        sum_data = avg_data.reduce (t,s) -> t + s
        average = sum_data / avg_data.length
        next_point = (average - localStorage.lastImpression) / 2

        $('#dashboard_total_impressions').html(data.impressions)
        $('#dashboard_total_revenue').html(data.revenue)
        $('#dashboard_avg_impressions').html(parseInt(next_point).toLocaleString())
        $('#dashboard_total_subids').html(data.subids)
        plot.setData([chartData(average)])
        if(localStorage.lastImpression != null)
          axes = plot.getAxes()
          if(next_point > axes.yaxis.options.max)
            axes.yaxis.options.max = axes.yaxis.options.max + 2000
            plot.setupGrid()
        plot.draw()
    , 2000
