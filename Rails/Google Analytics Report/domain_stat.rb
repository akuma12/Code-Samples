require 'google/api_client'
require 'concerns/ga_response_parser'
class DomainStat < ActiveRecord::Base
  belongs_to :domain
  belongs_to :traffic_source
  validates_presence_of :domain_id, :date

  # My method for gathering Google Analytics data by domain and by traffic source. It uses dynamic metrics and dimensions,
  # so data can be pulled almost any which way.
  def self.get_google_analytics (domain_id, traffic_source_id, dimensions, metric, start_date = Date.yesterday.to_s(:db), end_date = Date.yesterday.to_s(:db))
    domain = Domain.find(domain_id)
    if traffic_source_id.present?
      traffic_source = TrafficSource.find(traffic_source_id)
    else
      traffic_source = nil
    end
    client = Google::APIClient.new(:application_name => 'something you like', :application_version => '1')
    key_file = File.join(Rails.root, 'lib/keys/API Project-8856808807d2.p12')
    key = Google::APIClient::PKCS12.load_key(key_file, 'notasecret')
    service_account = Google::APIClient::JWTAsserter.new(
        '573806711604@developer.gserviceaccount.com',
        ['https://www.googleapis.com/auth/analytics.readonly', 'https://www.googleapis.com/auth/prediction'],
        key)
    client.authorization = service_account.authorize

    analytics = client.discovered_api('analytics', 'v3')

    if traffic_source.present?
      ga_sources = traffic_source.ga_code.split(',')

      ga_source_filter = ''

      ga_sources.each do |ga_source|
        ga_source_filter += "ga:source==#{ga_source},"
      end

      ga_source_filter = ga_source_filter.chomp(',') + ';'
    else
      ga_source_filter = ''
    end
    parameters = {
        'ids'         => "ga:#{domain.google_analytics_id}",
        'start-date'  => start_date,
        'end-date'    => end_date,
        'metrics'     => metric,
        'dimensions'  => dimensions,
        'filters'     => "#{ga_source_filter}ga:medium=@cpc,ga:medium=@cpm,ga:medium==organic"
    }

    result = client.execute(:api_method => analytics.data.ga.get, :parameters => parameters)

    ga_result = GaResponseParser.new(result.body)
    {rows: ga_result.to_h}
  end

  # This is the old method I used to call nightly to populate the domain_stats table. No longer needed as I
  # now pull GA data in real-time.
  def self.populate_data (domain_id, start_date = Date.yesterday.to_s(:db), end_date = Date.yesterday.to_s(:db))
    users = get_google_analytics(domain_id, 'ga:sessions,ga:pageviews,ga:avgTimeonSite,ga:bounceRate', start_date, end_date)
    users.each do |user|
      traffic_source = TrafficSource.where('ga_code like ?', "%#{user[0].to_s.downcase}%").first || TrafficSource.new(id: 0)
      self.create(domain_id: domain_id, date: start_date, number_of_users: user[3], number_of_page_views: user[4], time_on_site: user[5], source: user[0], article: user[1].truncate(255), device: user[2], traffic_source_id: traffic_source.id) unless user[3].nil? or user[4].nil?
    end
  end

  def self.by_domain(domain)
    return where(nil) if domain.blank?
    where(domain_stats: {domain_id: domain})
  end

  def self.group_by_source(check)
    return group(nil) unless check
    group('traffic_source_id')
  end

  def self.group_by_article(check)
    return group(nil) unless check
    group('article')
  end

  def self.group_by_device(check)
    return group(nil) unless check
    group('device')
  end

  def self.group_by_date(check)
    return group(nil) unless check
    group('date')
  end
end
