status = DSDC::ShipmentStatus.new(@shipment)

json.EstimatedStandardDay status.transit_days
json.ProNumber status.pro_number
json.ShipmentMilestoneStatus status.milestone_status
json.UpdatedETA status.updated_eta&.iso8601
