class Broker::ExportColumnsController < Broker::BrokerController
  INPUT_NAMES = [ 'columns[]', 'report[columns][]' ].freeze

  layout false

  def show
    @record_class = params[:record_type].constantize if Report::Runnable.record_type_available?(params[:record_type], current_user)
    @association = params[:association].to_s
    return head(:not_found) unless @record_class && ExporterService.association_available?(@record_class, @association, current_user)

    @mark_internal = params[:mark_internal] == 'true'
    @name = INPUT_NAMES.include?(params[:name]) ? params[:name] : INPUT_NAMES.first

    respond_to do |format|
      format.html { fresh_when(etag: [ @record_class.name, @association, @mark_internal, @name, current_user ]) }
    end
  end
end
