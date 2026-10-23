module ExportableController
  extend ActiveSupport::Concern

  included do
    helper_method :export_filters, :export_record_class, :exportable?
  end

  private

  attr_reader :export_record_class

  def export_columns
    columns = params[:columns]
    columns if columns.is_a?(Array)
  end

  def export_filters = @export_filters.to_h

  def exportable? = export_record_class.present?

  def respond_with_export(records, filters: {})
    @export_record_class = records.klass
    @export_filters = filters.stringify_keys

    respond_to do |format|
      format.csv { send_export(records, :csv) }
      format.html do
        @pagy, paginated_records = pagy(records)
        instance_variable_set(:"@#{controller_name}", paginated_records)
      end
      format.yaml { send_export(records, :yaml) }
    end
  end

  def send_export(records, format)
    exporter = ExporterService.new(records, authorizable: current_user, columns: export_columns)
    return unless stale?(etag: exporter)

    filename = "#{records.model_name.human(count: :other)} #{(exporter.updated_at || Time.current).iso8601(0)}.#{format}"
    send_data(exporter.public_send(:"to_#{format}"), filename:)
  end
end
