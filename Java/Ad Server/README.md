Ad Server
=========

These are a couple of the classes that I use in my ad server that is written in Java using the Play Framework
(https://www.playframework.com).

Java and Play
-------------

Java is a pretty new language to me, and this is the first project that I've actually written using the language. Play
made things considerably easier as it uses an MVC pattern, with conventions that are pretty similar to Rails.

Java was an interesting (and sometimes frustrating) experience for me as a web developer. Most languages used on the web
aren't strictly typed, such as Javascript, PHP, and to an extent, Ruby. In the past when programming in VB.NET, I've
really enjoyed strictly typed languages, as it gives me less opportunity to shoot my foot off.

Examples
--------

These examples form the core of the Redis real-time data system. The Data class contains all of the methods used to
keep impression counts, and read from and write to Redis.

One of the things I discovered with Redis connection pooling is that you have to very carefully maintain connections. I
began to notice memory leaks in my first iteration of the code, and found that uncaught exceptions can leave dead
connections hanging around in memory, and Java's garbage collection would simply leave them there. So now I make
extensive use of try/catch blocks to catch those exceptions and use the Jedis library's methods to return those dead
resources. This reduced my memory leak issue considerably.