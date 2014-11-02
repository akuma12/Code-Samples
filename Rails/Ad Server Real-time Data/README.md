Ad Server Real-time Data Dashboard
==================================

This is the dashboard that I created to track real-time impressions coming from my ad server.

I'm using [Flot,http://www.flotcharts.org] as my charting library, which has some basic real-time capabilities.
In order to track real-time stats,
we use Redis. However, early in the ad server project, we discovered that updating Redis with every impression served
was causing too many reads and writes to happen. So now we used a delayed read/write system, which forced us to get
creative when it came to our real-time dashboard. I now sample the number of impressions counted in Redis every two
seconds and store them in the browser's localStorage. To determine the average number of impressions per second, I take
the average of the last 5 samples and divide them by two. We write to Redis every 10 seconds, so this gives us a fairly
accurate view of how many impressions we are serving at any given time.