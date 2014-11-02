class RevenuesController < ApplicationController
  before_action :set_revenue, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource param_method: :revenue_params, except: [:domain_stats, :advertisers, :advertiser_types, :roi, :advertisers_by_month]

  # GET /revenues
  # GET /revenues.json
  def index
    @revenues = @revenues.includes([:domain, :advertiser]).order(:created_at)
  end

  # New way of using Google Analytics stats for a site to determine Revenue Per Session and Cost Per Click.
  # This pulls the stats from Google Analytics in real time and uses them to calculate ECPM, which is used
  # to calculate revenue by a number of different dimensions.
  def new_domain_stats
    @domains = Domain.accessible_by(current_ability).order(:name)
    @traffic_sources = TrafficSource.order(:name)
    @dimensions_list = {'Date' => 'ga:date', 'Source' => 'ga:source', 'Article' => 'ga:pagePathLevel1', 'Device' => 'ga:deviceCategory', 'Campaign' => 'ga:campaign'}
    dimensions = params[:dimensions] || %w{ga:date}
    dimensions = dimensions.join(',')
    @ecpm = {}
    @cost = {}

    if params[:domain_id].present? and params[:traffic_source_id].present?
      @stats = DomainStat.get_google_analytics(params[:domain_id], params[:traffic_source_id], dimensions, 'ga:sessions,ga:pageviews,ga:avgTimeonSite,ga:bounceRate', cookies[:start].to_date.to_s(:db), cookies[:end].to_date.to_s(:db))
      page_views = DomainStat.get_google_analytics(params[:domain_id], nil, 'ga:date', 'ga:pageviews', cookies[:start].to_date.to_s(:db), cookies[:end].to_date.to_s(:db))
      sessions = DomainStat.get_google_analytics(params[:domain_id], params[:traffic_source_id], 'ga:date', 'ga:sessions', cookies[:start].to_date.to_s(:db), cookies[:end].to_date.to_s(:db))
      sessions_by_date = sessions[:rows].each_with_object({}) { |u,h| h[u['date']] = u['sessions'] }

      page_views[:rows].each do |page_view|
        date = page_view['date']
        revenue = Revenue.accessible_by(current_ability).select('sum(amount) as amount').where(date: date).by_domain(params[:domain]).first
        if revenue.present? and revenue.amount.present?
          @ecpm[date] = revenue.amount / ((page_view['pageviews'].to_f * 6) / 1000)
        else
          @ecpm[date] = 0
        end
      end

      @stats[:rows].each do |stat|
        date = stat['date']
        spend = Spend.accessible_by(current_ability).select('amount').where(date: date, traffic_source_id: params[:traffic_source_id]).by_domain(params[:domain_id]).first

        percent_of_total = stat['sessions'].to_f / sessions_by_date[date].to_f

        if spend.present? and spend.amount.present?
          stat['cost'] = spend.amount * percent_of_total
          stat['cpc'] = stat['cost'].to_f / stat['sessions'].to_f
        else
          stat['cost'] = 0
          stat['cpc'] = 0
        end
        if @ecpm[date].present?
          stat['revenue'] = ((stat['pageviews'].to_f * 6) / 1000) * @ecpm[date]
          stat['rps'] = stat['revenue'] / stat['sessions'].to_f
        else
          stat['revenue'] = 0
          stat['rps'] = 0
        end
        if stat['revenue'] > 0 and stat['cost'] > 0
          stat['roi'] = ((stat['revenue'] - stat['cost']) / stat['cost']) * 100
        else
          stat['roi'] = 0
        end
      end
    end

    render 'reports/new_domain_stats'
  end

  # Old way of using Google Analytics to calculate revenue. I used to store GA data in a table, which was updated nightly.
  # This was cumbersome because every time we wanted to see a new dimension, a new column had to be added to the table and a new
  # method had to be created.
  def old_domain_stats
    @domains = Domain.accessible_by(current_ability).order(:name)
    @revenues = Revenue.accessible_by(current_ability).select('sum(amount) as amount, date').where(date: cookies[:start].to_date..cookies[:end].to_date).by_domain(params[:domain]).group('date').order('date desc')
    @domain_stats = DomainStat.accessible_by(current_ability).select('date, traffic_sources.name as source, sum(number_of_users) as number_of_users, sum(number_of_page_views) as number_of_page_views').joins(:traffic_source).where(date: cookies[:start].to_date..cookies[:end].to_date).by_domain(params[:domain]).group('date').group_by_source(true).order('date desc')
    @spends = Spend.accessible_by(current_ability).select('sum(amount) as amount, date, traffic_sources.name as source').joins(:traffic_source).where(date: cookies[:start].to_date..cookies[:end].to_date).by_domain(params[:domain]).group('date, traffic_source_id').order('date desc')
    @page_views_by_date = Hash[DomainStat.accessible_by(current_ability).select('date, sum(number_of_page_views) as number_of_page_views').where(date: cookies[:start].to_date..cookies[:end].to_date).by_domain(params[:domain]).group('date').order('date desc').map {|pv| [pv.date, pv.number_of_page_views].flatten}]

    @revenues_by_date = {}
    @rev_by_domain_stat = {totals: {revenue: 0, spend: 0, number_of_users: 0, number_of_page_views: 0}}
    @revenues.each do |revenue|
      @revenues_by_date[revenue.date] = revenue.amount
      @rev_by_domain_stat[:totals][:revenue] += revenue.amount
    end
    @spends.each do |spend|
      @rev_by_domain_stat[spend.date] ||= {}
      @rev_by_domain_stat[spend.date][spend.source] ||= {revenue: 0, spend: 0, number_of_users: 0, number_of_page_views: 0, ecpm: 0}
      @rev_by_domain_stat[spend.date][spend.source][:spend] = spend.amount
      @rev_by_domain_stat[:totals][:spend] += spend.amount
    end
    @domain_stats.each do |domain_stat|
      @rev_by_domain_stat[domain_stat.date] ||= {}
      @rev_by_domain_stat[domain_stat.date][domain_stat.source] ||= {revenue: 0, spend: 0, number_of_users: 0, number_of_page_views: 0, ecpm: 0}
      @rev_by_domain_stat[domain_stat.date][domain_stat.source][:number_of_users] = domain_stat.number_of_users
      @rev_by_domain_stat[:totals][:number_of_users] += domain_stat.number_of_users
      @rev_by_domain_stat[domain_stat.date][domain_stat.source][:number_of_page_views] = domain_stat.number_of_page_views
      @rev_by_domain_stat[:totals][:number_of_page_views] += domain_stat.number_of_page_views
      if @revenues_by_date[domain_stat.date].present? and @rev_by_domain_stat[domain_stat.date][domain_stat.source][:number_of_page_views] != 0
        @rev_by_domain_stat[domain_stat.date][domain_stat.source][:ecpm] = @revenues_by_date[domain_stat.date] / ((@page_views_by_date[domain_stat.date] * 6) / 1000)
        @rev_by_domain_stat[domain_stat.date][domain_stat.source][:revenue] = ((@rev_by_domain_stat[domain_stat.date][domain_stat.source][:number_of_page_views] * 6) / 1000) * @rev_by_domain_stat[domain_stat.date][domain_stat.source][:ecpm]
      end
    end

    render 'reports/domain_stats'
  end

  # GET /revenues/1
  # GET /revenues/1.json
  def show
  end

  # GET /revenues/new
  def new
    @revenue = Revenue.new
    if current_user.has_role? :admin
      @domains = Domain.order(:name)
    else
      @domains = current_user.organization.domains.order(:name)
    end
  end

  # GET /revenues/1/edit
  def edit
    if current_user.has_role? :admin
      @domains = Domain.order(:name)
    else
      @domains = current_user.organization.domains.order(:name)
    end
  end

  # POST /revenues
  # POST /revenues.json
  def create
    @revenue = Revenue.new(revenue_params)

    respond_to do |format|
      if @revenue.save
        format.html { redirect_to action: 'index', notice: 'Revenue was successfully created.' }
        format.json { render action: 'show', status: :created, location: @revenue }
      else
        format.html { render action: 'new' }
        format.json { render json: @revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /revenues/1
  # PATCH/PUT /revenues/1.json
  def update
    respond_to do |format|
      if @revenue.update(revenue_params)
        format.html { redirect_to action: 'index', notice: 'Revenue was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /revenues/1
  # DELETE /revenues/1.json
  def destroy
    @revenue.destroy
    respond_to do |format|
      format.html { redirect_to revenues_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_revenue
      @revenue = Revenue.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def revenue_params
      params.require(:revenue).permit(:amount, :date, :domain_id, :advertiser_id, :impressions)
    end
end
