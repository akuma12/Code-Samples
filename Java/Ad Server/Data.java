package lib;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicInteger;

import play.Logger;
import redis.clients.jedis.Jedis;
import redis.clients.jedis.exceptions.JedisConnectionException;
import root.*;

public class Data {
  public static void incrementDailyBanners(Long id) {
    AtomicInteger count = Global.ops_daily_banners.get(id);
    if(count == null) {
      Global.ops_daily_banners.putIfAbsent(id, new AtomicInteger(1));
    } else {
      count.getAndIncrement();
    }
  }
  
  public static void incrementDailyCampaigns(Long id) {
    AtomicInteger count = Global.ops_daily_campaigns.get(id);
    if(count == null) {
      Global.ops_daily_campaigns.putIfAbsent(id, new AtomicInteger(1));
    } else {
      count.getAndIncrement();
    }
  }
  
  public static void incrementDailySubids(String id) {
    AtomicInteger count = Global.ops_daily_subids.get(id);
    if(count == null) {
      Global.ops_daily_subids.putIfAbsent(id, new AtomicInteger(1));
    } else {
      count.getAndIncrement();
    }
  }
  
  public static void incrementHourlyZones(Long id) {
    AtomicInteger count = Global.ops_hourly_zones.get(id);
    if(count == null) {
      Global.ops_hourly_zones.putIfAbsent(id, new AtomicInteger(1));
    } else {
      count.getAndIncrement();
    }
  }
  
  public static void incrementHourlyBanners(Long id) {
    AtomicInteger count = Global.ops_hourly_banners.get(id);
    if(count == null) {
      Global.ops_hourly_banners.putIfAbsent(id, new AtomicInteger(1));
    } else {
      count.getAndIncrement();
    }
  }
  
  public static void incrementUserCaps(String hash, Long banner_id, Integer expire) throws JedisConnectionException {
    Jedis jedis = null;
    try {
      jedis = Global.redis.userJedisPool.getResource();
      jedis.hincrBy(hash, Long.toString(banner_id), 1L);
      if(expire != -1) {
        jedis.expire(hash, expire);
      }
    }
    catch(Exception e) {
      Logger.error(e.toString());
    }
    finally {
      Global.redis.userJedisPool.returnResource(jedis);
    }  
  }
  
  public static Map<Long,Integer> getUserCaps(String hash) throws JedisConnectionException {
    Jedis jedis = null;
    Map<String,String> tempMap = null;
    Map<Long,Integer> newMap = null;
    try {
      jedis = Global.redis.userJedisPool.getResource();
      tempMap = jedis.hgetAll(hash);
      newMap = new HashMap<Long,Integer>();
      for (Map.Entry<String, String> entry : tempMap.entrySet()) {
        newMap.put(Long.parseLong(entry.getKey(), 10), Integer.parseInt(entry.getValue()));
      }
      return newMap;
    }
    catch(Exception e) {
      Logger.error(e.toString());
      return newMap;
    }
    finally {
      Global.redis.userJedisPool.returnResource(jedis);
    }
  }
  
  public static ConcurrentMap<Long, Integer> getDailyBanners() throws JedisConnectionException {
    Jedis jedis = null;
    Map<String,String> tempMap = null;
    ConcurrentMap<Long,Integer> newMap = null;
    try {
      jedis = Global.redis.dailyBannerJedisPool.getResource();
      String date = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
      tempMap = jedis.hgetAll("banner:counts:" + date);
      newMap = new ConcurrentHashMap<Long,Integer>();
      for (Map.Entry<String, String> entry : tempMap.entrySet()) {
        newMap.put(Long.parseLong(entry.getKey(), 10), Integer.parseInt(entry.getValue()));
      }
      return newMap;
    }
    catch(Exception e) {
      Logger.error(e.toString());
      Global.redis.dailyBannerJedisPool.returnBrokenResource(jedis);
      return newMap;
    }
    finally {
      Global.redis.dailyBannerJedisPool.returnResource(jedis);
    }
  }
  
  public static ConcurrentMap<Long, Integer> getDailyCampaigns() throws JedisConnectionException {
    Jedis jedis = null;
    Map<String,String> tempMap = null;
    ConcurrentMap<Long,Integer> newMap = null;
    try {
      jedis = Global.redis.dailyCampaignJedisPool.getResource();
      String date = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
      tempMap = jedis.hgetAll("campaign:counts:" + date);
      newMap = new ConcurrentHashMap<Long,Integer>();
      for (Map.Entry<String, String> entry : tempMap.entrySet()) {
        newMap.put(Long.parseLong(entry.getKey(), 10), Integer.parseInt(entry.getValue()));
      }
      return newMap;
    }
    catch(Exception e) {
      Logger.error(e.toString());
      Global.redis.dailyCampaignJedisPool.returnBrokenResource(jedis);
      return newMap;
    }
    finally {
      Global.redis.dailyCampaignJedisPool.returnResource(jedis);
    }
  }
  
  public static void updateDailyBanners() throws JedisConnectionException {
    Jedis jedis = null;
    try {
      jedis = Global.redis.dailyBannerJedisPool.getResource();
      String date = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
      Map<Long, AtomicInteger> snapshot = new HashMap<Long, AtomicInteger>(Global.ops_daily_banners);
      Global.ops_daily_banners.clear();
      for (Map.Entry<Long, AtomicInteger> entry : snapshot.entrySet()) {
        jedis.hincrBy("banner:counts:" + date, Long.toString(entry.getKey()), entry.getValue().longValue());
      }
    }
    catch(JedisConnectionException e) {
      Logger.error(e.toString());
      Global.redis.dailyBannerJedisPool.returnBrokenResource(jedis);
    }
    finally {
      Global.redis.dailyBannerJedisPool.returnResource(jedis);
    }
    
  }
  
  public static void updateDailyCampaigns() throws JedisConnectionException {
    Jedis jedis = null;
    try {
      jedis = Global.redis.dailyCampaignJedisPool.getResource();
      String date = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
      Map<Long, AtomicInteger> snapshot = new HashMap<Long, AtomicInteger>(Global.ops_daily_campaigns);
      Global.ops_daily_campaigns.clear();
      for (Map.Entry<Long, AtomicInteger> entry : snapshot.entrySet()) {
        jedis.hincrBy("campaign:counts:" + date, Long.toString(entry.getKey()), entry.getValue().longValue());
      }
    }
    catch(JedisConnectionException e) {
      Logger.error(e.toString());
      Global.redis.dailyCampaignJedisPool.returnBrokenResource(jedis);
    }
    finally {
      Global.redis.dailyCampaignJedisPool.returnResource(jedis);
    }
  }
  
  public static void updateDailySubids() throws JedisConnectionException {
    Jedis jedis = null;
    try {
      jedis = Global.redis.dailySubidJedisPool.getResource();
      String date = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
      Map<String, AtomicInteger> snapshot = new HashMap<String, AtomicInteger>(Global.ops_daily_subids);
      Global.ops_daily_subids.clear();
      for (Map.Entry<String, AtomicInteger> entry : snapshot.entrySet()) {
        jedis.hincrBy("subid:counts:" + date, entry.getKey(), entry.getValue().longValue());
      }
    }
    catch(JedisConnectionException e) {
      Logger.error(e.toString());
      Global.redis.dailySubidJedisPool.returnBrokenResource(jedis);
    }
    finally {
      Global.redis.dailySubidJedisPool.returnResource(jedis);
    }
  }
  
  public static void updateHourlyZones() throws JedisConnectionException {
    Jedis jedis = null;
    try {
      jedis = Global.redis.hourlyZoneJedisPool.getResource();
      String date = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
      String hour = new SimpleDateFormat("HH").format(new Date());
      Map<Long, AtomicInteger> snapshot = new HashMap<Long, AtomicInteger>(Global.ops_hourly_zones);
      Global.ops_hourly_zones.clear();
      for (Map.Entry<Long, AtomicInteger> entry : snapshot.entrySet()) {
        jedis.hincrBy("zone:counts:" + date + ":" + Long.toString(entry.getKey()), hour, entry.getValue().longValue());
      }
    }
    catch(JedisConnectionException e) {
      Logger.error(e.toString());
      Global.redis.hourlyZoneJedisPool.returnBrokenResource(jedis);
    }
    finally {
      Global.redis.hourlyZoneJedisPool.returnResource(jedis);
    }
  }
  
  public static void updateHourlyBanners() throws JedisConnectionException {
    Jedis jedis = null;
    try {
      jedis = Global.redis.hourlyBannerJedisPool.getResource();
      String date = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
      String hour = new SimpleDateFormat("HH").format(new Date());
      Map<Long, AtomicInteger> snapshot = new HashMap<Long, AtomicInteger>(Global.ops_hourly_banners);
      Global.ops_hourly_banners.clear();
      for (Map.Entry<Long, AtomicInteger> entry : snapshot.entrySet()) {
        jedis.hincrBy("banner:counts:" + date + ":" + Long.toString(entry.getKey()), hour, entry.getValue().longValue());
      }
    }
    catch(JedisConnectionException e) {
      Logger.error(e.toString());
      Global.redis.hourlyBannerJedisPool.returnBrokenResource(jedis);
    }
    finally {
      Global.redis.hourlyBannerJedisPool.returnResource(jedis);
    }
  }
}
