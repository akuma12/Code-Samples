class DashboardController < ApplicationController
  skip_before_filter :authenticate_user!, only: :realtime_stats, if: -> { request.env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest' }
  def index

  end

  def realtime_stats
    # TOTAL BANNERS
    begin
      @banners = Rails.cache.fetch('accessible_banners', namespace: -> { current_user.organization_id }, expires_in: 10.minutes) do
        Banner.accessible_by(current_ability)
      end
      imps = $banner_daily_redis.hmget("banner:counts:#{Date.today.to_s}", @banners.map(&:id))

      @impressions = 0
      imps.each do |value|
        @impressions += value.to_i
      end

      # SUBID's
      subid = $subid_daily_redis.hgetall("subid:counts:#{Date.today.to_s}")

      @subids = 0
      subid.each do |key, value|
        @subids += 1
      end

      data = {}
      data[:impressions]     = number_with_delimiter(@impressions.to_i)
      data[:numimpressions]  = @impressions.to_i
      data[:subids]          = number_with_delimiter(@subids.to_i)

      render json: data
    rescue
      data = {}
      data[:impressions]     = 0
      data[:numimpressions]  = 0
      data[:subids]          = 0

      render json: data
    end
  end
end