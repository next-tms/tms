class Broker::ReportsController < Broker::BrokerController
  PREVIEW_LIMIT = 25

  before_action :build_report, only: %i[create new]
  before_action :set_report, only: %i[destroy edit show update]
  before_action :set_date_range, only: %i[create edit new show update]
  before_action :set_form_options, only: %i[create edit new show update]

  def create
    return render_preview(:new) if params[:preview]
    return redirect_to(saved_report_location, notice: "Saved #{@report.name}") if @report.save

    render(:new, status: :unprocessable_content)
  end

  def destroy
    @report.destroy!

    redirect_to([ :broker, Report ], notice: "Deleted #{@report.name}")
  end

  def edit
    respond_to do |format|
      format.html { fresh_when(etag: [ @report, @from, @to, @today, viewer_etag ]) }
    end
  end

  def index
    authorize!(Report)

    @presets = Report::Preset.all
    @reports = @broker.reports.includes(:created_by).order(:name)

    respond_to do |format|
      format.html { fresh_when(etag: [ @presets, @reports, @reports.map(&:created_by), viewer_etag ]) }
    end
  end

  def new
    respond_to do |format|
      format.html { fresh_when(etag: [ @report.attributes, @from, @to, @today, viewer_etag ]) }
    end
  end

  def show
    remember_date_range

    respond_to do |format|
      format.csv { send_report(:csv) }
      format.html do
        @preview = preview_exporter
        fresh_when(etag: [ @report, @preview, @from, @to, @today, viewer_etag ])
      end
      format.yaml { send_report(:yaml) }
    end
  end

  def update
    @report.assign_attributes(report_params.except(:record_type))

    return render_preview(:edit) if params[:preview]
    return redirect_to(saved_report_location, notice: "Saved #{@report.name}") if @report.save

    render(:edit, status: :unprocessable_content)
  end

  private

  def build_report
    @report = @broker.reports.new(created_by: current_user)
    @report.assign_attributes(action_name == 'create' ? report_params : new_report_attributes)
    if action_name == 'new' && @report.columns.blank? && @report.record_class
      @report.columns = ExporterService.default_columns(@report.record_class, current_user)
    end

    authorize!(@report)
  end

  def duplicate_attributes(source)
    {
      columns: source.columns,
      date_attribute: source.date_attribute,
      filters: source.filters,
      from_days_ago: source.from_days_ago,
      name: "#{source.name} (Copy)",
      record_type: source.record_type,
      to_days_ago: source.to_days_ago
    }
  end

  def duplicate_source
    return if params[:duplicate].blank?

    Report::Preset.find(params[:duplicate]) || @broker.reports.find_by(id: params[:duplicate])
  end

  def export_filters
    [ params[:q], params[:filters] ].select { |query| query.respond_to?(:to_unsafe_h) }.map(&:to_unsafe_h).reduce({}, :merge)
  end

  def new_report_attributes
    source = duplicate_source
    return duplicate_attributes(source) if source

    columns = params[:columns] if params[:columns].is_a?(Array)

    { columns:, filters: export_filters, record_type: params[:record_type] }
  end

  def ordered_columns(columns, column_order) = (column_order & columns) + (columns - column_order)

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

  def remember_date_range
    return unless @report.date_range? && allowed_to?(:update?, @report)
    return unless parse_date(params[:from]) && parse_date(params[:to])

    @report.remember_date_range(@from, @to, @today)
  end

  def report_basename
    return "#{@report.name} #{@from.iso8601} to #{@to.iso8601}" if @report.date_range?

    "#{@report.name} #{Time.current.iso8601(0)}"
  end

  def report_params
    attributes = params
                 .expect(report: [ :date_attribute, :name, :record_type, { column_order: [], columns: [], filters: {} } ])
                 .with_defaults(filters: {})
    column_order = attributes.delete(:column_order) || []
    return attributes unless attributes[:columns]

    attributes.merge(columns: ordered_columns(attributes[:columns], column_order))
  end

  def saved_report_location = [ :broker, @report, @report.date_range? ? { from: @from.iso8601, to: @to.iso8601 } : {} ]

  def send_report(format)
    exporter = @report.exporter(current_user, from: @from, to: @to)
    send_data(exporter.public_send(:"to_#{format}"), filename: "#{report_basename}.#{format}") if stale?(etag: exporter)
  end

  def set_date_range
    @today = ActiveSupport::TimeZone.new(Setting.value!(:time_zone_name)).today
    default_from, default_to = @report.default_date_range(@today)

    @from = parse_date(params[:from]) || default_from
    @to = parse_date(params[:to]) || default_to
  end

  def set_form_options
    return if @report.record_class.blank?

    @date_attributes = @report.date_attributes(current_user)
  end

  def set_report
    @report = Report::Preset.find(params[:id]) || @broker.reports.find(params[:id])
    authorize!(@report)
  end

  def viewer_etag = [ current_user, current_user.roles.sort ]
end
