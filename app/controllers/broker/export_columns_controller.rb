class Broker::ExportColumnsController < Broker::BrokerController
  INPUT_NAMES = [ 'columns[]', 'report[columns][]' ].freeze

  layout false

  def show
    @record_class = params[:record_type].constantize if Report::RECORD_TYPES.include?(params[:record_type])
    @association = params[:association].to_s
    return head(:not_found) unless @record_class && ExporterService.association_available?(@record_class, @association, current_user)

    @mark_internal = params[:mark_internal] == 'true'
    @name = INPUT_NAMES.include?(params[:name]) ? params[:name] : INPUT_NAMES.first
    @selected = params[:selected].is_a?(Array) ? params[:selected] : []

    respond_to do |format|
      format.html { fresh_when(etag: [ @record_class.name, @association, @mark_internal, @name, @selected, current_user ]) }
    end
  end
end
