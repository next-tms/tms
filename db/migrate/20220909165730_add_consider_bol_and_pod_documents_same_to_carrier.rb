class AddConsiderBolAndPodDocumentsSameToCarrier < ActiveRecord::Migration[7.0]
  def change
    add_column :carriers, :consider_bol_and_pod_documents_same, :boolean, default: false
  end
end
