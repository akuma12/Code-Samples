package lib;

import play.Logger;
import play.Play;
import redis.clients.jedis.*;

public class Redis {
  private static JedisPoolConfig poolConfig;
  public JedisPool userJedisPool;
  public JedisPool dailyBannerJedisPool;
  public JedisPool dailyCampaignJedisPool;
  public JedisPool dailySubidJedisPool;
  public JedisPool hourlyZoneJedisPool;
  public JedisPool hourlyBannerJedisPool;

  public Redis() {
    poolConfig = new JedisPoolConfig();
    poolConfig.setMaxTotal(100);
    poolConfig.setMaxIdle(10);
    poolConfig.setMinIdle(1);
    poolConfig.setNumTestsPerEvictionRun(10);
    poolConfig.setTestOnBorrow(true);
    poolConfig.setTestOnReturn(true);
    poolConfig.setTestWhileIdle(true);
    poolConfig.setTimeBetweenEvictionRunsMillis(30000);
    try {
      userJedisPool =  new JedisPool(poolConfig, Play.application().configuration().getString("redis.user.host"), Play.application().configuration().getInt("redis.user.port"),5000);
    }
    catch (Exception e) {
      Logger.error(e.toString());
    }
    try {
      dailyBannerJedisPool = new JedisPool(poolConfig, Play.application().configuration().getString("redis.daily_banner.host"), Play.application().configuration().getInt("redis.daily_banner.port"),5000,Play.application().configuration().getString("redis.password"));
    }
    catch (Exception e) {
      Logger.error(e.toString());
    }
    try {
      dailyCampaignJedisPool = new JedisPool(poolConfig, Play.application().configuration().getString("redis.daily_campaign.host"), Play.application().configuration().getInt("redis.daily_campaign.port"),5000,Play.application().configuration().getString("redis.password"));
    }
    catch (Exception e) {
      Logger.error(e.toString());
    }
    try {
      dailySubidJedisPool = new JedisPool(poolConfig, Play.application().configuration().getString("redis.daily_subid.host"), Play.application().configuration().getInt("redis.daily_subid.port"),5000,Play.application().configuration().getString("redis.password"));
    }
    catch (Exception e) {
      Logger.error(e.toString());
    }
    try {
      hourlyZoneJedisPool = new JedisPool(poolConfig, Play.application().configuration().getString("redis.hourly_zone.host"), Play.application().configuration().getInt("redis.hourly_zone.port"),5000,Play.application().configuration().getString("redis.password"));
    }
    catch (Exception e) {
      Logger.error(e.toString());
    }
    try {
      hourlyBannerJedisPool = new JedisPool(poolConfig, Play.application().configuration().getString("redis.hourly_banner.host"), Play.application().configuration().getInt("redis.hourly_banner.port"),5000,Play.application().configuration().getString("redis.password"));
    }
    catch (Exception e) {
      Logger.error(e.toString());
    }
  }
}
