# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_27_190449) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accessorials", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "code"
    t.string "reactive_shipping_code"
  end

  create_table "addresses", force: :cascade do |t|
    t.string "street"
    t.string "street2"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.decimal "latitude", precision: 15, scale: 10
    t.decimal "longitude", precision: 15, scale: 10
    t.text "verification_info"
    t.text "original_attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "types"
    t.string "ref"
    t.string "time_zone"
    t.text "google_places_spot_cached"
  end

  create_table "areas", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_areas_on_name"
  end

  create_table "broker_accessorials", force: :cascade do |t|
    t.bigint "broker_id", null: false
    t.bigint "accessorial_id"
    t.string "name"
    t.float "cost"
    t.float "upcharge"
    t.float "upcharge_percent"
    t.integer "upcharge_cents", default: 0, null: false
    t.string "upcharge_currency", default: "USD", null: false
    t.boolean "broker_only", default: true
    t.string "code"
    t.integer "flat_charge_cents", default: 0, null: false
    t.string "flat_charge_currency", default: "USD", null: false
    t.bigint "broker_customer_id"
    t.index ["accessorial_id"], name: "index_broker_accessorials_on_accessorial_id"
    t.index ["broker_customer_id"], name: "index_broker_accessorials_on_broker_customer_id"
    t.index ["broker_id"], name: "index_broker_accessorials_on_broker_id"
  end

  create_table "broker_carriers", id: :serial, force: :cascade do |t|
    t.integer "carrier_id"
    t.integer "broker_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "account"
    t.string "username"
    t.string "password"
    t.string "account_desc"
    t.text "default_bol_notes"
    t.bigint "check_mailing_address_id"
    t.bigint "broker_customer_id"
    t.integer "days_to_pay_after_invoice_date", default: 30
    t.boolean "create_invoice_on_pickup"
    t.integer "quote_padding_cents", default: 0, null: false
    t.string "quote_padding_currency", default: "USD", null: false
    t.index ["broker_customer_id"], name: "index_broker_carriers_on_broker_customer_id"
    t.index ["broker_id"], name: "index_broker_carriers_on_broker_id"
    t.index ["carrier_id"], name: "index_broker_carriers_on_carrier_id"
    t.index ["check_mailing_address_id"], name: "index_broker_carriers_on_check_mailing_address_id"
  end

  create_table "broker_customer_sales_reps", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "broker_customer_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["broker_customer_id"], name: "index_broker_customer_sales_reps_on_broker_customer_id"
    t.index ["user_id"], name: "index_broker_customer_sales_reps_on_user_id"
  end

  create_table "broker_customers", force: :cascade do |t|
    t.bigint "customer_id"
    t.bigint "broker_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "shipment_string_patterns"
    t.text "default_bol_notes"
    t.boolean "can_quote", default: false
    t.integer "default_upcharge_cents", default: 0, null: false
    t.string "default_upcharge_currency", default: "USD", null: false
    t.float "default_upcharge_percentage"
    t.boolean "always_show_quotes_based_on_calculated_classes", default: true
    t.bigint "primary_pickup_address_id"
    t.text "valid_freight_classes"
    t.boolean "enable_auto_freight_class", default: true
    t.index ["broker_id"], name: "index_broker_customers_on_broker_id"
    t.index ["customer_id"], name: "index_broker_customers_on_customer_id"
    t.index ["primary_pickup_address_id"], name: "index_broker_customers_on_primary_pickup_address_id"
  end

  create_table "brokers", id: :serial, force: :cascade do |t|
    t.string "name"
    t.bigint "address_id"
    t.string "phone"
    t.string "customer_service_email"
    t.integer "first_load_id"
    t.text "default_bol_notes"
    t.index ["address_id"], name: "index_brokers_on_address_id"
  end

  create_table "carrier_areas", force: :cascade do |t|
    t.bigint "carrier_id", null: false
    t.bigint "to_area_id", null: false
    t.bigint "from_area_id", null: false
    t.index ["carrier_id"], name: "index_carrier_areas_on_carrier_id"
    t.index ["from_area_id"], name: "index_carrier_areas_on_from_area_id"
    t.index ["to_area_id"], name: "index_carrier_areas_on_to_area_id"
  end

  create_table "carrier_contacts", force: :cascade do |t|
    t.bigint "broker_id"
    t.bigint "carrier_id"
    t.bigint "contact_id"
    t.index ["broker_id"], name: "index_carrier_contacts_on_broker_id"
    t.index ["carrier_id"], name: "index_carrier_contacts_on_carrier_id"
    t.index ["contact_id"], name: "index_carrier_contacts_on_contact_id"
  end

  create_table "carriers", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "scac"
    t.boolean "acts_as_broker", default: false
    t.bigint "check_mailing_address_id"
    t.boolean "has_traceable_pickup_confirmation", default: false
    t.index ["check_mailing_address_id"], name: "index_carriers_on_check_mailing_address_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "broker_id"
    t.string "first_name"
    t.string "last_name"
    t.string "job_title"
    t.string "email"
    t.string "work_phone"
    t.string "mobile_phone"
    t.string "label"
    t.text "comments"
    t.index ["broker_id"], name: "index_contacts_on_broker_id"
  end

  create_table "customer_contacts", force: :cascade do |t|
    t.bigint "broker_id"
    t.bigint "customer_id"
    t.bigint "contact_id"
    t.index ["broker_id"], name: "index_customer_contacts_on_broker_id"
    t.index ["contact_id"], name: "index_customer_contacts_on_contact_id"
    t.index ["customer_id"], name: "index_customer_contacts_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
  end

  create_table "events", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "active_shipping_code"
  end

  create_table "items", force: :cascade do |t|
    t.integer "l"
    t.integer "w"
    t.integer "h"
    t.integer "nmfc"
    t.boolean "hazmat"
    t.boolean "refrigerated"
    t.string "desc"
    t.integer "packaging_id"
    t.integer "weight"
    t.integer "quantity"
    t.float "forced_class"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "location_areas", force: :cascade do |t|
    t.bigint "area_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["area_id"], name: "index_location_areas_on_area_id"
    t.index ["location_id"], name: "index_location_areas_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "zip_code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["zip_code"], name: "index_locations_on_zip_code"
  end

  create_table "overlength_rules", force: :cascade do |t|
    t.bigint "broker_carrier_id", null: false
    t.integer "min_length"
    t.integer "max_length"
    t.integer "cost_cents", default: 0, null: false
    t.string "cost_currency", default: "USD", null: false
    t.index ["broker_carrier_id"], name: "index_overlength_rules_on_broker_carrier_id"
  end

  create_table "packagings", force: :cascade do |t|
    t.string "name"
  end

  create_table "payment_transactions", force: :cascade do |t|
    t.bigint "shipment_id"
    t.string "pro"
    t.integer "balance_cents", default: 0, null: false
    t.string "balance_currency", default: "USD", null: false
    t.integer "paid_cents", default: 0, null: false
    t.string "paid_currency", default: "USD", null: false
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "payment_id"
    t.boolean "additional_charge"
    t.date "due_on"
    t.bigint "broker_carrier_id"
    t.bigint "broker_id", null: false
    t.integer "week"
    t.bigint "created_by_id", null: false
    t.string "invoice"
    t.string "legacy_load_id"
    t.index ["broker_carrier_id"], name: "index_payment_transactions_on_broker_carrier_id"
    t.index ["payment_id"], name: "index_payment_transactions_on_payment_id"
    t.index ["shipment_id"], name: "index_payment_transactions_on_shipment_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "broker_carrier_id", null: false
    t.string "method"
    t.string "method_reference"
    t.bigint "created_by_id", null: false
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "due_on"
    t.date "paid_on"
    t.bigint "broker_id", null: false
    t.integer "week"
    t.integer "paid_cents", default: 0, null: false
    t.string "paid_currency", default: "USD", null: false
    t.index ["approved_by_id"], name: "index_payments_on_approved_by_id"
    t.index ["broker_carrier_id"], name: "index_payments_on_broker_carrier_id"
    t.index ["created_by_id"], name: "index_payments_on_created_by_id"
  end

  create_table "pricing_rules", force: :cascade do |t|
    t.bigint "carrier_area_id", null: false
    t.bigint "broker_carrier_id", null: false
    t.integer "cost_per_pallet_cents", default: 0, null: false
    t.string "cost_per_pallet_currency", default: "USD", null: false
    t.integer "max_pallets"
    t.integer "min_pallets"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["broker_carrier_id"], name: "index_pricing_rules_on_broker_carrier_id"
    t.index ["carrier_area_id"], name: "index_pricing_rules_on_carrier_area_id"
    t.index ["max_pallets"], name: "index_pricing_rules_on_max_pallets"
    t.index ["min_pallets"], name: "index_pricing_rules_on_min_pallets"
  end

  create_table "quickbooks_credentials", force: :cascade do |t|
    t.bigint "broker_id", null: false
    t.datetime "access_token_expires_at"
    t.datetime "refresh_token_expires_at"
    t.text "access_token"
    t.text "realm_id"
    t.text "refresh_token"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["broker_id"], name: "index_quickbooks_credentials_on_broker_id"
  end

  create_table "rate_accessorials", force: :cascade do |t|
    t.bigint "rate_id", null: false
    t.bigint "accessorial_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["accessorial_id"], name: "index_rate_accessorials_on_accessorial_id"
    t.index ["rate_id"], name: "index_rate_accessorials_on_rate_id"
  end

  create_table "rates", force: :cascade do |t|
    t.bigint "broker_carrier_id", null: false
    t.bigint "tracking_carrier_id"
    t.bigint "broker_customer_id"
    t.bigint "shipment_id", null: false
    t.integer "cost_cents", default: 0, null: false
    t.string "cost_currency", default: "USD", null: false
    t.text "error"
    t.datetime "expires_at"
    t.string "reference"
    t.text "request"
    t.text "response"
    t.integer "transit_days"
    t.boolean "with_calculated_freight_classes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "incomplete"
    t.string "shipment_fingerprint"
    t.string "uid"
    t.string "reactive_shipping_service_type"
    t.index ["broker_carrier_id"], name: "index_rates_on_broker_carrier_id"
    t.index ["broker_customer_id"], name: "index_rates_on_broker_customer_id"
    t.index ["reactive_shipping_service_type"], name: "index_rates_on_reactive_shipping_service_type"
    t.index ["shipment_id"], name: "index_rates_on_shipment_id"
    t.index ["tracking_carrier_id"], name: "index_rates_on_tracking_carrier_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "shipment_accessorials", force: :cascade do |t|
    t.bigint "shipment_id", null: false
    t.bigint "accessorial_id", null: false
    t.index ["accessorial_id"], name: "index_shipment_accessorials_on_accessorial_id"
    t.index ["shipment_id"], name: "index_shipment_accessorials_on_shipment_id"
  end

  create_table "shipment_broker_accessorials", force: :cascade do |t|
    t.bigint "shipment_id", null: false
    t.bigint "broker_accessorial_id", null: false
    t.integer "cost_cents", default: 0, null: false
    t.string "cost_currency", default: "USD", null: false
    t.integer "charge_cents", default: 0, null: false
    t.string "charge_currency", default: "USD", null: false
    t.index ["broker_accessorial_id"], name: "index_shipment_broker_accessorials_on_broker_accessorial_id"
    t.index ["shipment_id"], name: "index_shipment_broker_accessorials_on_shipment_id"
  end

  create_table "shipment_items", force: :cascade do |t|
    t.bigint "shipment_id"
    t.bigint "item_id"
    t.index ["item_id"], name: "index_shipment_items_on_item_id"
    t.index ["shipment_id"], name: "index_shipment_items_on_shipment_id"
  end

  create_table "shipments", id: :serial, force: :cascade do |t|
    t.integer "broker_id"
    t.integer "broker_carrier_id"
    t.string "shipper_name"
    t.string "shipper_reference"
    t.string "customer_reference"
    t.string "pro"
    t.string "pickup_confirmation"
    t.boolean "picked_up"
    t.integer "priority"
    t.time "shipper_unavailable_at"
    t.time "receiver_available_at"
    t.time "receiver_unavailable_at"
    t.integer "load"
    t.string "receiver_name"
    t.string "shipper_contact_name"
    t.string "shipper_contact_phone"
    t.string "shipper_contact_email"
    t.string "receiver_contact_name"
    t.string "receiver_contact_phone"
    t.string "receiver_contact_email"
    t.string "shipper_bol"
    t.bigint "shipper_address_id"
    t.bigint "receiver_address_id"
    t.string "bol"
    t.date "pickup_on"
    t.boolean "lift_gate_delivery"
    t.boolean "notify"
    t.boolean "lift_gate_pickup"
    t.datetime "delivered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "deliver_by"
    t.integer "total_charges_cents", default: 0, null: false
    t.string "total_charges_currency", default: "USD", null: false
    t.integer "total_cost_cents", default: 0, null: false
    t.string "total_cost_currency", default: "USD", null: false
    t.string "quote_id"
    t.datetime "picked_up_at"
    t.datetime "dispatched_at"
    t.datetime "shipper_available_at"
    t.datetime "out_for_delivery_at"
    t.integer "load_id"
    t.integer "value_cents", default: 0, null: false
    t.string "value_currency", default: "USD", null: false
    t.text "bol_notes"
    t.integer "carrier_cost_cents", default: 0, null: false
    t.string "carrier_cost_currency", default: "USD", null: false
    t.text "broker_notes"
    t.text "customer_notes"
    t.integer "carrier_charge_cents", default: 0, null: false
    t.string "carrier_charge_currency", default: "USD", null: false
    t.datetime "canceled_at"
    t.bigint "broker_customer_id"
    t.bigint "updated_by_id"
    t.datetime "quoted_delivery_by"
    t.datetime "promised_delivery_by"
    t.boolean "truckload", default: false
    t.date "pending_appointment_since"
    t.datetime "delivery_appointment_at"
    t.date "delivery_appointment_on"
    t.bigint "tracking_carrier_id"
    t.string "tracking_carrier_pro"
    t.string "tracking_carrier_pickup_confirmation"
    t.string "pickup_hours_start_at"
    t.string "pickup_hours_end_at"
    t.string "delivery_hours_start_at"
    t.string "delivery_hours_end_at"
    t.bigint "applied_rate_id"
    t.string "pickup_eta_at"
    t.datetime "pickup_driver_assigned_at"
    t.datetime "departed_origin_terminal_at"
    t.boolean "quote_only", default: false
    t.index ["applied_rate_id"], name: "index_shipments_on_applied_rate_id"
    t.index ["broker_customer_id"], name: "index_shipments_on_broker_customer_id"
    t.index ["broker_notes"], name: "index_shipments_on_broker_notes"
    t.index ["receiver_address_id"], name: "index_shipments_on_receiver_address_id"
    t.index ["shipper_address_id"], name: "index_shipments_on_shipper_address_id"
    t.index ["tracking_carrier_id"], name: "index_shipments_on_tracking_carrier_id"
    t.index ["updated_by_id"], name: "index_shipments_on_updated_by_id"
  end

  create_table "terminals", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.bigint "carrier_id", null: false
    t.string "phone"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["address_id"], name: "index_terminals_on_address_id"
    t.index ["carrier_id"], name: "index_terminals_on_carrier_id"
  end

  create_table "tracking_events", force: :cascade do |t|
    t.bigint "shipment_id", null: false
    t.bigint "address_id"
    t.bigint "event_id", null: false
    t.boolean "public", default: true
    t.datetime "at"
    t.string "time_zone"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "terminal_id"
    t.string "city"
    t.string "state"
    t.string "country_alpha2", limit: 2
    t.string "reactive_carrier_fingerprint"
    t.bigint "user_id"
    t.index ["address_id"], name: "index_tracking_events_on_address_id"
    t.index ["event_id"], name: "index_tracking_events_on_event_id"
    t.index ["shipment_id"], name: "index_tracking_events_on_shipment_id"
    t.index ["terminal_id"], name: "index_tracking_events_on_terminal_id"
    t.index ["user_id"], name: "index_tracking_events_on_user_id"
  end

  create_table "upcharge_rules", force: :cascade do |t|
    t.bigint "broker_customer_id", null: false
    t.bigint "packaging_id", null: false
    t.integer "max"
    t.integer "min"
    t.integer "upcharge_cents", default: 0, null: false
    t.string "upcharge_currency", default: "USD", null: false
    t.float "upcharge_percentage"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["broker_customer_id"], name: "index_upcharge_rules_on_broker_customer_id"
    t.index ["packaging_id"], name: "index_upcharge_rules_on_packaging_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "first_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "broker_id"
    t.string "phone"
    t.boolean "receive_sms_notifications"
    t.string "last_name"
    t.bigint "broker_customer_id"
    t.boolean "receive_email_notifications", default: true
    t.string "time_zone"
    t.boolean "receive_notifications_from_self", default: true
    t.index ["broker_customer_id"], name: "index_users_on_broker_customer_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "websites", force: :cascade do |t|
    t.bigint "broker_id"
    t.string "domain"
    t.string "copyright_holder"
    t.text "logo_image_data"
    t.text "css"
    t.string "slogan"
    t.text "desc"
    t.text "v_card_logo_base64"
    t.string "sign_out_url"
    t.string "footer_url"
    t.string "modal_url"
    t.string "manifest_url"
    t.string "homepage"
    t.index ["broker_id"], name: "index_websites_on_broker_id"
  end

  add_foreign_key "broker_accessorials", "accessorials"
  add_foreign_key "broker_accessorials", "broker_customers"
  add_foreign_key "broker_accessorials", "brokers"
  add_foreign_key "broker_carriers", "addresses", column: "check_mailing_address_id"
  add_foreign_key "broker_carriers", "broker_customers"
  add_foreign_key "broker_carriers", "brokers"
  add_foreign_key "broker_carriers", "carriers"
  add_foreign_key "broker_customer_sales_reps", "broker_customers"
  add_foreign_key "broker_customer_sales_reps", "users"
  add_foreign_key "broker_customers", "addresses", column: "primary_pickup_address_id"
  add_foreign_key "broker_customers", "brokers"
  add_foreign_key "broker_customers", "customers"
  add_foreign_key "brokers", "addresses"
  add_foreign_key "carrier_areas", "areas", column: "from_area_id"
  add_foreign_key "carrier_areas", "areas", column: "to_area_id"
  add_foreign_key "carrier_areas", "carriers"
  add_foreign_key "carrier_contacts", "brokers"
  add_foreign_key "carrier_contacts", "carriers"
  add_foreign_key "carrier_contacts", "contacts"
  add_foreign_key "carriers", "addresses", column: "check_mailing_address_id"
  add_foreign_key "contacts", "brokers"
  add_foreign_key "customer_contacts", "brokers"
  add_foreign_key "customer_contacts", "contacts"
  add_foreign_key "customer_contacts", "customers"
  add_foreign_key "location_areas", "areas"
  add_foreign_key "location_areas", "locations"
  add_foreign_key "overlength_rules", "broker_carriers"
  add_foreign_key "payment_transactions", "broker_carriers"
  add_foreign_key "payment_transactions", "brokers"
  add_foreign_key "payment_transactions", "payments"
  add_foreign_key "payment_transactions", "shipments"
  add_foreign_key "payment_transactions", "users", column: "created_by_id"
  add_foreign_key "payments", "broker_carriers"
  add_foreign_key "payments", "brokers"
  add_foreign_key "payments", "users", column: "approved_by_id"
  add_foreign_key "payments", "users", column: "created_by_id"
  add_foreign_key "pricing_rules", "broker_carriers"
  add_foreign_key "pricing_rules", "carrier_areas"
  add_foreign_key "quickbooks_credentials", "brokers"
  add_foreign_key "rate_accessorials", "accessorials"
  add_foreign_key "rate_accessorials", "rates"
  add_foreign_key "rates", "broker_carriers"
  add_foreign_key "rates", "broker_customers"
  add_foreign_key "rates", "carriers", column: "tracking_carrier_id"
  add_foreign_key "rates", "shipments"
  add_foreign_key "shipment_accessorials", "accessorials"
  add_foreign_key "shipment_accessorials", "shipments"
  add_foreign_key "shipment_broker_accessorials", "broker_accessorials"
  add_foreign_key "shipment_broker_accessorials", "shipments"
  add_foreign_key "shipment_items", "items"
  add_foreign_key "shipment_items", "shipments"
  add_foreign_key "shipments", "addresses", column: "receiver_address_id"
  add_foreign_key "shipments", "addresses", column: "shipper_address_id"
  add_foreign_key "shipments", "broker_customers"
  add_foreign_key "shipments", "carriers", column: "tracking_carrier_id"
  add_foreign_key "shipments", "rates", column: "applied_rate_id"
  add_foreign_key "shipments", "users", column: "updated_by_id"
  add_foreign_key "terminals", "addresses"
  add_foreign_key "terminals", "carriers"
  add_foreign_key "tracking_events", "addresses"
  add_foreign_key "tracking_events", "events"
  add_foreign_key "tracking_events", "shipments"
  add_foreign_key "tracking_events", "terminals"
  add_foreign_key "tracking_events", "users"
  add_foreign_key "upcharge_rules", "broker_customers"
  add_foreign_key "upcharge_rules", "packagings"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "broker_customers"
  add_foreign_key "websites", "brokers"
end
