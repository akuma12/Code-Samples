Google Analytics Revenue Report
===============================

This is a report that I wrote that uses Google Analytics data that is gathered via their API, and combines it with recorded
revenue and cost data to calculate values such as Revenue per User and Cost per Click for websites. It was created for a company
that monetizes blogs, and this report is part of a portal that allows blog owners to track their revenue and traffic costs.

Old Way
-------

Originally I was storing the Google Analytics data in a table called domain_stats. This data was updated nightly. I quickly found
this method to be pretty untenable, as every time we wanted to look at the data using a different dimension (such as by blog article
or device category) a new column had to be added to the table and the data completely refreshed. I had to figure out a way to pull
the data from Google Analytics directly and apply it to the revenue and cost data we had stored.

New Way
-------

I'm somewhat irritated that I didn't think of this sooner, but I finally figured out a way to pull the GA data, using any number of
metrics and dimensions, and combine that with our revenue and cost data to break down Revenue per User and Cost per Click as finely
grained as we wanted, all without having to alter the database. This method is a little slower, as it pulls data straight from Google
each time, but the benefits were pretty amazing.