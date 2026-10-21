class Broker::ReportsController < Broker::BrokerController
  PREVIEW_LIMIT = 25

  before_action :build_report, only: %i[create new]
  before_action :set_report, only: %i[destroy edit show update]
  before_action :set_date_range, only: %i[create edit new show update]
  before_action :set_form_options, only: %i[create edit new show update]

  def create
    return render_preview(:new) if params[:preview]
    return redirect_to(broker_report_path(@report), notice: "Saved #{@report.name}") if @report.save

    render(:new, status: :unprocessable_content)
  end

  def destroy
    @report.destroy!

    redirect_to(broker_reports_path, notice: "Deleted #{@report.name}")
  end

  def edit
    respond_to do |format|
      format.html { fresh_when(etag: [ @report, current_user ]) }
    end
  end

  def index
    authorize!(Report)

    @presets = Report::Preset.all
    @reports = @broker.reports.includes(:created_by).order(:name)

    respond_to do |format|
      format.html { fresh_when(etag: [ @presets, @reports, current_user ]) }
    end
  end

  def new
    respond_to do |format|
      format.html { fresh_when(etag: [ @report.attributes, current_user ]) }
    end
  end

  def show
    respond_to do |format|
      format.csv { send_report(:csv) }
      format.html do
        @preview = preview_exporter
        fresh_when(etag: [ @report, @preview ], last_modified: @preview.updated_at)
      end
      format.yaml { send_report(:yaml) }
    end
  end

  def update
    @report.assign_attributes(report_params)

    return render_preview(:edit) if params[:preview]
    return redirect_to(broker_report_path(@report), notice: "Saved #{@report.name}") if @report.save

    render(:edit, status: :unprocessable_content)
  end

  private

  def build_report
    @report = @broker.reports.new(created_by: current_user)
    @report.assign_attributes(action_name == 'create' ? report_params : new_report_attributes)
    @report.columns = ExporterService.default_columns(@report.record_class, current_user) if @report.columns.blank? && @report.record_class

    authorize!(@report)
  end

  def duplicate_attributes(source)
    {
      columns: source.columns,
      date_attribute: source.date_attribute,
      filters: source.filters,
      name: "#{source.name} (Copy)",
      record_type: source.record_type
    }
  end

  def duplicate_source
    return if params[:duplicate].blank?

    Report::Preset.find(params[:duplicate]) || @broker.reports.find_by(id: params[:duplicate])
  end

  def export_filters
    query = params[:q].respond_to?(:to_unsafe_h) ? params[:q].to_unsafe_h : {}
    query.merge(Array(params[:scopes]).index_with(true))
  end

  def new_report_attributes
    source = duplicate_source
    return duplicate_attributes(source) if source

    columns = params[:columns] if params[:columns].is_a?(Array)

    { columns:, filters: export_filters, record_type: params[:record_type] }
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  def preview_exporter
    @report.exporter(current_user, from: @from, limit: PREVIEW_LIMIT, to: @to)
  end

  def render_preview(template)
    @preview = preview_exporter if @report.valid?

    render(template, status: @preview ? :ok : :unprocessable_content)
  end

  def report_basename
    return "#{@report.name} #{@from.iso8601} to #{@to.iso8601}" if @report.date_range?

    "#{@report.name} #{Time.current.iso8601(0)}"
  end

  def report_params
    params.expect(report: [ :date_attribute, :name, :record_type, { columns: [], filters: {} } ]).with_defaults(filters: {})
  end

  def send_report(format)
    exporter = @report.exporter(current_user, from: @from, to: @to)
    send_data(exporter.public_send(:"to_#{format}"), filename: "#{report_basename}.#{format}") if stale?(exporter)
  end

  def set_date_range
    today = ActiveSupport::TimeZone.new(Setting.value!(:time_zone_name)).today

    @from = parse_date(params[:from]) || today.beginning_of_month
    @to = parse_date(params[:to]) || today
  end

  def set_form_options
    return if @report.record_class.blank?

    @columns = ExporterService.available_columns(@report.record_class, current_user)
    @customer_columns = ExporterService.customer_columns(@report.record_class)
    @date_attributes = @report.date_attributes(current_user)
  end

  def set_report
    @report = Report::Preset.find(params[:id]) || @broker.reports.find(params[:id])
    authorize!(@report)
  end
end
