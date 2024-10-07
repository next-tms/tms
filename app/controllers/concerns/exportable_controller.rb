module ExportableController
  extend ActiveSupport::Concern

  included do
    helper_method :export_record_class, :exportable?
  end

  private

  attr_reader :export_record_class

  def export_columns
    columns = params[:columns]
    columns if columns.is_a?(Array)
  end

  def exportable? = export_record_class.present?

  def respond_with_export(records)
    @export_record_class = records.klass

    respond_to do |format|
      format.csv { send_export(records, :csv) }
      format.html do
        @pagy, paginated_records = pagy(records)
        instance_variable_set(:"@#{controller_name}", paginated_records)
        fresh_when(paginated_records)
      end
      format.yaml { send_export(records, :yaml) }
    end
  end

  def send_export(records, format)
    exporter = ExporterService.new(records, authorizable: current_user, columns: export_columns)
    return unless stale?(exporter)

    filename = "#{records.model_name.human(count: :other)} #{exporter.updated_at.iso8601(0)}.#{format}"
    send_data(exporter.public_send(:"to_#{format}"), filename:)
  end
end
