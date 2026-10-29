# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_29_045816) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"

  create_table "accessorials", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.boolean "fee", default: false
    t.string "freight_kit_code"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "city"
    t.string "country_alpha2", limit: 2, null: false
    t.datetime "created_at", precision: nil, null: false
    t.text "google_places_spot_cached"
    t.datetime "google_places_spot_updated_at", precision: nil
    t.decimal "latitude", precision: 15, scale: 10
    t.decimal "longitude", precision: 15, scale: 10
    t.text "open_street_map_result_cached"
    t.datetime "open_street_map_result_updated_at", precision: nil
    t.text "original_attributes"
    t.string "ref"
    t.string "region_iso31662"
    t.datetime "smarty_streets_result_updated_at", precision: nil
    t.bigint "standardized_address_id"
    t.string "street"
    t.string "street2"
    t.string "time_zone_name"
    t.datetime "updated_at", precision: nil, null: false
    t.text "verification_info"
    t.string "zip_code"
    t.index ["country_alpha2"], name: "index_addresses_on_country_alpha2"
    t.index ["region_iso31662"], name: "index_addresses_on_region_iso31662"
    t.index ["standardized_address_id"], name: "index_addresses_on_standardized_address_id"
  end

  create_table "areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_areas_on_name"
  end

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.jsonb "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "banks", force: :cascade do |t|
    t.string "account_number"
    t.integer "accounting_account_id"
    t.string "kind", null: false
    t.string "name"
  end

  create_table "broker_accessorials", force: :cascade do |t|
    t.bigint "accessorial_id"
    t.bigint "broker_customer_id"
    t.boolean "broker_only", default: true
    t.string "code"
    t.float "cost"
    t.boolean "fee", default: false
    t.integer "flat_charge_cents", default: 0, null: false
    t.string "flat_charge_currency", default: "USD", null: false
    t.string "name"
    t.float "upcharge"
    t.integer "upcharge_cents", default: 0, null: false
    t.string "upcharge_currency", default: "USD", null: false
    t.float "upcharge_percent"
    t.index ["accessorial_id"], name: "index_broker_accessorials_on_accessorial_id"
    t.index ["broker_customer_id"], name: "index_broker_accessorials_on_broker_customer_id"
  end

  create_table "broker_carriers", id: :serial, force: :cascade do |t|
    t.string "account"
    t.string "account_desc"
    t.text "accounting_notes"
    t.integer "accounting_vendor_id"
    t.bigint "broker_customer_id"
    t.integer "carrier_id"
    t.bigint "check_mailing_address_id"
    t.boolean "create_invoice_on_pickup"
    t.datetime "created_at", precision: nil, null: false
    t.integer "days_to_pay_after_invoice_date", default: 30
    t.text "default_bol_notes"
    t.string "encrypted_api_key"
    t.boolean "ignore_bol_requires_tracking_number", default: false
    t.string "password"
    t.integer "quote_padding_cents", default: 0, null: false
    t.string "quote_padding_currency", default: "USD", null: false
    t.integer "shipments_count"
    t.datetime "updated_at", precision: nil, null: false
    t.string "username"
    t.string "website_password"
    t.string "website_username"
    t.index ["broker_customer_id"], name: "index_broker_carriers_on_broker_customer_id"
    t.index ["carrier_id"], name: "index_broker_carriers_on_carrier_id"
    t.index ["check_mailing_address_id"], name: "index_broker_carriers_on_check_mailing_address_id"
    t.index ["shipments_count"], name: "index_broker_carriers_on_shipments_count"
  end

  create_table "broker_countries", force: :cascade do |t|
    t.string "country_alpha2", limit: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_alpha2"], name: "index_broker_countries_on_country_alpha2"
  end

  create_table "broker_customer_dispatchers", force: :cascade do |t|
    t.bigint "broker_customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["broker_customer_id"], name: "index_broker_customer_dispatchers_on_broker_customer_id"
    t.index ["user_id"], name: "index_broker_customer_dispatchers_on_user_id"
  end

  create_table "broker_customer_sales_reps", force: :cascade do |t|
    t.bigint "broker_customer_id", null: false
    t.integer "commission_flat_cents", default: 0, null: false
    t.string "commission_flat_currency", default: "USD", null: false
    t.decimal "commission_percent", default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["broker_customer_id"], name: "index_broker_customer_sales_reps_on_broker_customer_id"
    t.index ["user_id"], name: "index_broker_customer_sales_reps_on_user_id"
  end

  create_table "broker_customers", force: :cascade do |t|
    t.string "accounting_customer_id"
    t.boolean "always_show_quotes_based_on_calculated_classes", default: true
    t.boolean "can_quote", default: false
    t.datetime "created_at", precision: nil, null: false
    t.bigint "customer_id"
    t.text "default_bol_notes"
    t.integer "default_upcharge_cents", default: 0, null: false
    t.string "default_upcharge_currency", default: "USD", null: false
    t.float "default_upcharge_percentage", default: 0.0
    t.boolean "enable_auto_freight_class", default: true
    t.boolean "ignore_value_on_api_quotes", default: false
    t.text "internal_notes"
    t.bigint "office_address_id", null: false
    t.string "preferred_broker_carriers_kind"
    t.bigint "primary_pickup_address_id", null: false
    t.bigint "receivables_contact_id"
    t.string "receivables_schedule", default: "immediately"
    t.boolean "requires_carrier_bol_on_receivables", default: true
    t.boolean "requires_carrier_pod_on_receivables", default: true
    t.boolean "requires_charges_confirmed_on_receivables", default: false
    t.boolean "requires_customer_reference_number_on_receivables", default: false
    t.boolean "requires_shipment_delivery_before_receivable", default: true
    t.boolean "requires_shipment_shipper_reference_on_receivables", default: false
    t.text "shipment_string_patterns"
    t.datetime "updated_at", precision: nil, null: false
    t.text "valid_freight_classes"
    t.index ["customer_id"], name: "index_broker_customers_on_customer_id"
    t.index ["office_address_id"], name: "index_broker_customers_on_office_address_id"
    t.index ["primary_pickup_address_id"], name: "index_broker_customers_on_primary_pickup_address_id"
    t.index ["receivables_contact_id"], name: "index_broker_customers_on_receivables_contact_id"
    t.index ["requires_carrier_bol_on_receivables"], name: "index_broker_customers_on_requires_carrier_bol_on_receivables"
    t.index ["requires_carrier_pod_on_receivables"], name: "index_broker_customers_on_requires_carrier_pod_on_receivables"
  end

  create_table "carrier_areas", force: :cascade do |t|
    t.bigint "carrier_id", null: false
    t.bigint "from_area_id", null: false
    t.bigint "to_area_id", null: false
    t.index ["carrier_id", "from_area_id", "to_area_id"], name: "idx_on_carrier_id_from_area_id_to_area_id_bcd543b955", unique: true
    t.index ["carrier_id"], name: "index_carrier_areas_on_carrier_id"
    t.index ["from_area_id"], name: "index_carrier_areas_on_from_area_id"
    t.index ["to_area_id"], name: "index_carrier_areas_on_to_area_id"
  end

  create_table "carriers", id: :serial, force: :cascade do |t|
    t.boolean "acts_as_broker", default: false
    t.bigint "broker_billing_address_id"
    t.bigint "check_mailing_address_id"
    t.boolean "consider_bol_and_pod_documents_same", default: false
    t.string "encrypted_api_key"
    t.string "encrypted_proxy_url"
    t.boolean "has_traceable_pickup_confirmation", default: false
    t.integer "mc_number"
    t.string "name"
    t.string "scac"
    t.index ["broker_billing_address_id"], name: "index_carriers_on_broker_billing_address_id"
    t.index ["check_mailing_address_id"], name: "index_carriers_on_check_mailing_address_id"
    t.index ["name"], name: "index_carriers_on_name", unique: true
    t.index ["scac"], name: "index_carriers_on_scac", unique: true
  end

  create_table "claim_items", force: :cascade do |t|
    t.integer "balance_cents", default: 0, null: false
    t.string "balance_currency", default: "USD", null: false
    t.bigint "claim_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "payee_id", null: false
    t.string "payee_type", null: false
    t.integer "total_cents", default: 0, null: false
    t.string "total_currency", default: "USD", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_claim_items_on_claim_id"
    t.index ["payee_type", "payee_id"], name: "index_claim_items_on_payee"
  end

  create_table "claims", force: :cascade do |t|
    t.integer "balance_cents", default: 0, null: false
    t.string "balance_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.date "due_on"
    t.bigint "shipment_id", null: false
    t.integer "total_cents", default: 0, null: false
    t.string "total_currency", default: "USD", null: false
    t.datetime "updated_at", null: false
    t.index ["due_on"], name: "index_claims_on_due_on"
    t.index ["shipment_id"], name: "index_claims_on_shipment_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.bigint "contact_id"
    t.datetime "created_at", null: false
    t.bigint "discussion_topic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_comments_on_contact_id"
    t.index ["discussion_topic_id"], name: "index_comments_on_discussion_topic_id"
  end

  create_table "commissions", force: :cascade do |t|
    t.integer "amount_cents", default: 0, null: false
    t.string "amount_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.boolean "paid", default: false
    t.bigint "shipment_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["shipment_id"], name: "index_commissions_on_shipment_id"
    t.index ["user_id"], name: "index_commissions_on_user_id"
  end

  create_table "contact_roles", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id", "role"], name: "index_contact_roles_on_contact_id_and_role", unique: true
    t.index ["contact_id"], name: "index_contact_roles_on_contact_id"
    t.index ["role"], name: "index_contact_roles_on_role"
  end

  create_table "contacts", force: :cascade do |t|
    t.text "comments"
    t.bigint "companyable_id"
    t.string "companyable_type"
    t.string "email"
    t.string "first_name"
    t.string "job_title"
    t.string "label"
    t.string "last_name"
    t.string "mobile_phone"
    t.string "work_phone"
    t.index ["companyable_id", "companyable_type", "email"], name: "idx_on_companyable_id_companyable_type_email_1de3a153e6", unique: true
    t.index ["companyable_type", "companyable_id"], name: "index_contacts_on_companyable"
    t.index ["email"], name: "index_contacts_on_email", unique: true, where: "((companyable_id IS NULL) AND (companyable_type IS NULL) AND (email IS NOT NULL))"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name"
    t.index ["name"], name: "index_customers_on_name"
  end

  create_table "discussion_topics", force: :cascade do |t|
    t.string "contact_scope", null: false
    t.datetime "created_at", null: false
    t.bigint "discussion_id", null: false
    t.bigint "topic_id", null: false
    t.string "topic_type", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_scope"], name: "index_discussion_topics_on_contact_scope"
    t.index ["discussion_id"], name: "index_discussion_topics_on_discussion_id"
    t.index ["topic_type", "topic_id"], name: "index_discussion_topics_on_topic"
  end

  create_table "discussions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_type", "subject_id"], name: "index_discussions_on_subject"
  end

  create_table "document_preferences", force: :cascade do |t|
    t.bigint "broker_customer_id"
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.string "kind"
    t.datetime "updated_at", null: false
    t.index ["broker_customer_id"], name: "index_document_preferences_on_broker_customer_id"
    t.index ["contact_id"], name: "index_document_preferences_on_contact_id"
    t.index ["kind"], name: "index_document_preferences_on_kind"
  end

  create_table "events", force: :cascade do |t|
    t.string "active_shipping_code"
    t.datetime "created_at", null: false
    t.string "name"
    t.boolean "public_by_default", default: true, null: false
    t.datetime "updated_at", null: false
  end

  create_table "integration_mappings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "external_id", null: false
    t.bigint "integration_id", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_id"], name: "index_integration_mappings_on_integration_id"
    t.index ["record_type", "record_id", "integration_id"], name: "index_integration_mappings_uniqueness", unique: true
  end

  create_table "integrations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "credentials", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "name"], name: "index_integrations_on_kind_and_name", unique: true
  end

  create_table "items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "declared_freight_class"
    t.string "desc"
    t.integer "h"
    t.boolean "hazmat"
    t.integer "l"
    t.string "nmfc"
    t.integer "packaging_id"
    t.integer "quantity"
    t.boolean "refrigerated"
    t.bigint "shipment_id", null: false
    t.datetime "updated_at", null: false
    t.integer "w"
    t.integer "weight"
    t.index ["shipment_id"], name: "index_items_on_shipment_id"
  end

  create_table "location_areas", force: :cascade do |t|
    t.bigint "area_id", null: false
    t.datetime "created_at", null: false
    t.bigint "location_id", null: false
    t.datetime "updated_at", null: false
    t.index ["area_id"], name: "index_location_areas_on_area_id"
    t.index ["location_id"], name: "index_location_areas_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "region_iso31662", null: false
    t.datetime "updated_at", null: false
    t.string "zip_code"
    t.index ["region_iso31662"], name: "index_locations_on_region_iso31662"
    t.index ["zip_code"], name: "index_locations_on_zip_code"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "notifications_count"
    t.jsonb "params"
    t.bigint "record_id"
    t.string "record_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "read_at", precision: nil
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.datetime "seen_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "overlength_rules", force: :cascade do |t|
    t.bigint "broker_carrier_id", null: false
    t.integer "cost_cents", default: 0, null: false
    t.string "cost_currency", default: "USD", null: false
    t.integer "max_length"
    t.integer "min_length"
    t.index ["broker_carrier_id"], name: "index_overlength_rules_on_broker_carrier_id"
  end

  create_table "packagings", force: :cascade do |t|
    t.string "freight_kit_type"
    t.string "name"
    t.index ["freight_kit_type"], name: "index_packagings_on_freight_kit_type"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "payment_transactions", force: :cascade do |t|
    t.integer "accounting_bill_id"
    t.boolean "additional_charge"
    t.integer "balance_cents", default: 0, null: false
    t.string "balance_currency", default: "USD", null: false
    t.bigint "broker_carrier_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "due_on"
    t.string "invoice"
    t.string "legacy_load_id"
    t.text "notes"
    t.integer "paid_cents", default: 0, null: false
    t.string "paid_currency", default: "USD", null: false
    t.bigint "payment_id"
    t.string "pro"
    t.bigint "shipment_id"
    t.datetime "updated_at", null: false
    t.index ["broker_carrier_id"], name: "index_payment_transactions_on_broker_carrier_id"
    t.index ["payment_id"], name: "index_payment_transactions_on_payment_id"
    t.index ["shipment_id"], name: "index_payment_transactions_on_shipment_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "accounting_bill_payment_id"
    t.datetime "approved_at", precision: nil
    t.bigint "approved_by_id"
    t.bigint "bank_id"
    t.bigint "broker_carrier_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "due_on"
    t.string "method"
    t.string "method_reference"
    t.integer "paid_cents", default: 0, null: false
    t.string "paid_currency", default: "USD", null: false
    t.date "paid_on"
    t.bigint "payment_method_id"
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_payments_on_approved_by_id"
    t.index ["bank_id"], name: "index_payments_on_bank_id"
    t.index ["broker_carrier_id"], name: "index_payments_on_broker_carrier_id"
    t.index ["created_by_id"], name: "index_payments_on_created_by_id"
    t.index ["payment_method_id"], name: "index_payments_on_payment_method_id"
  end

  create_table "pickups", force: :cascade do |t|
    t.jsonb "api_errors", default: "[]", null: false
    t.text "api_request"
    t.text "api_response"
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", null: false
    t.bigint "dispatcher_id"
    t.string "pickup_confirmation"
    t.string "pro"
    t.bigint "rate_id", null: false
    t.datetime "requested_at", precision: nil
    t.bigint "shipment_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["dispatcher_id"], name: "index_pickups_on_dispatcher_id"
    t.index ["rate_id"], name: "index_pickups_on_rate_id"
    t.index ["shipment_id"], name: "index_pickups_on_shipment_id"
    t.index ["updated_by_id"], name: "index_pickups_on_updated_by_id"
  end

  create_table "preferred_broker_carriers", force: :cascade do |t|
    t.bigint "broker_carrier_id", null: false
    t.bigint "broker_customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["broker_carrier_id"], name: "index_preferred_broker_carriers_on_broker_carrier_id"
    t.index ["broker_customer_id"], name: "index_preferred_broker_carriers_on_broker_customer_id"
  end

  create_table "pricing_rules", force: :cascade do |t|
    t.bigint "broker_carrier_id", null: false
    t.bigint "carrier_area_id", null: false
    t.integer "cost_per_pallet_cents", default: 0, null: false
    t.string "cost_per_pallet_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.integer "max_pallets"
    t.integer "min_pallets"
    t.datetime "updated_at", null: false
    t.index ["broker_carrier_id"], name: "index_pricing_rules_on_broker_carrier_id"
    t.index ["carrier_area_id"], name: "index_pricing_rules_on_carrier_area_id"
    t.index ["max_pallets"], name: "index_pricing_rules_on_max_pallets"
    t.index ["min_pallets"], name: "index_pricing_rules_on_min_pallets"
  end

  create_table "problems", force: :cascade do |t|
    t.bigint "assigned_to_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.string "problematic_rule_code", null: false
    t.bigint "resolvable_id"
    t.string "resolvable_type"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.integer "suppressions_count"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_problems_on_assigned_to_id"
    t.index ["body"], name: "index_problems_on_body"
    t.index ["resolvable_type", "resolvable_id"], name: "index_problems_on_resolvable"
    t.index ["resolved_at"], name: "index_problems_on_resolved_at"
    t.index ["resolved_by_id"], name: "index_problems_on_resolved_by_id"
    t.index ["title"], name: "index_problems_on_title"
  end

  create_table "rate_accessorials", force: :cascade do |t|
    t.bigint "accessorial_id", null: false
    t.datetime "created_at", null: false
    t.bigint "rate_id", null: false
    t.datetime "updated_at", null: false
    t.index ["accessorial_id"], name: "index_rate_accessorials_on_accessorial_id"
    t.index ["rate_id"], name: "index_rate_accessorials_on_rate_id"
  end

  create_table "rates", force: :cascade do |t|
    t.jsonb "api_errors", default: "[]", null: false
    t.text "api_request"
    t.text "api_response"
    t.json "breakdown"
    t.bigint "broker_carrier_id", null: false
    t.bigint "broker_customer_id"
    t.integer "cost_cents", default: 0, null: false
    t.string "cost_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.boolean "declared_freight_classes", null: false
    t.datetime "expires_at", precision: nil
    t.string "freight_kit_service_type"
    t.boolean "incomplete"
    t.string "reference"
    t.string "shipment_fingerprint"
    t.bigint "shipment_id", null: false
    t.string "source"
    t.bigint "tracking_carrier_id"
    t.integer "transit_days"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["broker_carrier_id"], name: "index_rates_on_broker_carrier_id"
    t.index ["broker_customer_id"], name: "index_rates_on_broker_customer_id"
    t.index ["freight_kit_service_type"], name: "index_rates_on_freight_kit_service_type"
    t.index ["shipment_id"], name: "index_rates_on_shipment_id"
    t.index ["tracking_carrier_id"], name: "index_rates_on_tracking_carrier_id"
  end

  create_table "receivable_items", force: :cascade do |t|
    t.integer "charge_cents", default: 0, null: false
    t.string "charge_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "receivable_id", null: false
    t.datetime "updated_at", null: false
    t.index ["receivable_id"], name: "index_receivable_items_on_receivable_id"
  end

  create_table "receivables", force: :cascade do |t|
    t.string "accounting_invoice_id"
    t.datetime "authorized_at", precision: nil
    t.bigint "authorized_by_id"
    t.integer "balance_cents", default: 0, null: false
    t.string "balance_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.datetime "due_by", precision: nil
    t.boolean "invoiced", default: false
    t.datetime "paid_at", precision: nil
    t.datetime "sent_at"
    t.bigint "sent_by_id"
    t.bigint "shipment_id", null: false
    t.integer "total_cents", default: 0, null: false
    t.string "total_currency", default: "USD", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["authorized_at"], name: "index_receivables_on_authorized_at"
    t.index ["authorized_by_id"], name: "index_receivables_on_authorized_by_id"
    t.index ["created_by_id"], name: "index_receivables_on_created_by_id"
    t.index ["due_by"], name: "index_receivables_on_due_by"
    t.index ["invoiced"], name: "index_receivables_on_invoiced"
    t.index ["paid_at"], name: "index_receivables_on_paid_at"
    t.index ["sent_by_id"], name: "index_receivables_on_sent_by_id"
    t.index ["shipment_id"], name: "index_receivables_on_shipment_id", unique: true
    t.index ["updated_by_id"], name: "index_receivables_on_updated_by_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["key"], name: "index_settings_on_key"
  end

  create_table "shipment_accessorials", force: :cascade do |t|
    t.bigint "accessorial_id", null: false
    t.bigint "shipment_id", null: false
    t.index ["accessorial_id"], name: "index_shipment_accessorials_on_accessorial_id"
    t.index ["shipment_id"], name: "index_shipment_accessorials_on_shipment_id"
  end

  create_table "shipment_broker_accessorials", force: :cascade do |t|
    t.bigint "broker_accessorial_id", null: false
    t.integer "charge_cents", default: 0, null: false
    t.string "charge_currency", default: "USD", null: false
    t.integer "cost_cents", default: 0, null: false
    t.string "cost_currency", default: "USD", null: false
    t.bigint "shipment_id", null: false
    t.index ["broker_accessorial_id"], name: "index_shipment_broker_accessorials_on_broker_accessorial_id"
    t.index ["shipment_id"], name: "index_shipment_broker_accessorials_on_shipment_id"
  end

  create_table "shipments", id: :serial, force: :cascade do |t|
    t.bigint "applied_rate_id"
    t.string "bol"
    t.text "bol_notes"
    t.datetime "booked_at", precision: nil
    t.text "broker_and_broker_customer_notes"
    t.integer "broker_carrier_id"
    t.bigint "broker_customer_id"
    t.text "broker_notes"
    t.datetime "canceled_at", precision: nil
    t.integer "carrier_charge_cents", default: 0, null: false
    t.string "carrier_charge_currency", default: "USD", null: false
    t.integer "carrier_cost_cents", default: 0, null: false
    t.string "carrier_cost_currency", default: "USD", null: false
    t.boolean "charges_confirmed", default: false
    t.datetime "created_at", precision: nil
    t.bigint "created_by_id"
    t.text "customer_notes"
    t.string "customer_reference"
    t.datetime "delivered_at", precision: nil
    t.datetime "delivery_appointment_at", precision: nil
    t.date "delivery_appointment_on"
    t.date "delivery_eta_on"
    t.string "delivery_hours_end_at"
    t.string "delivery_hours_start_at"
    t.datetime "departed_origin_terminal_at", precision: nil
    t.datetime "dispatched_at", precision: nil
    t.bigint "dispatcher_id", null: false
    t.string "fingerprint"
    t.boolean "lift_gate_delivery"
    t.boolean "lift_gate_pickup"
    t.integer "load"
    t.integer "load_id"
    t.date "lost_on"
    t.boolean "notify"
    t.datetime "out_for_delivery_at", precision: nil
    t.date "pending_appointment_since"
    t.datetime "picked_up_at", precision: nil
    t.string "pickup_confirmation"
    t.datetime "pickup_driver_assigned_at", precision: nil
    t.string "pickup_eta_at"
    t.string "pickup_hours_end_at"
    t.string "pickup_hours_start_at"
    t.date "pickup_on"
    t.integer "priority"
    t.string "pro"
    t.datetime "promised_delivery_by", precision: nil
    t.text "public_notes"
    t.string "quote_id"
    t.boolean "quote_only", default: false
    t.datetime "quoted_delivery_by", precision: nil
    t.bigint "receiver_address_id"
    t.time "receiver_available_at"
    t.string "receiver_contact_email"
    t.string "receiver_contact_name"
    t.string "receiver_contact_phone"
    t.string "receiver_name"
    t.time "receiver_unavailable_at"
    t.bigint "shipper_address_id"
    t.datetime "shipper_available_at", precision: nil
    t.string "shipper_bol"
    t.string "shipper_contact_email"
    t.string "shipper_contact_name"
    t.string "shipper_contact_phone"
    t.string "shipper_name"
    t.string "shipper_reference"
    t.time "shipper_unavailable_at"
    t.string "status", null: false
    t.integer "total_charges_cents", default: 0, null: false
    t.string "total_charges_currency", default: "USD", null: false
    t.integer "total_cost_cents", default: 0, null: false
    t.string "total_cost_currency", default: "USD", null: false
    t.bigint "tracking_carrier_id"
    t.string "tracking_carrier_pickup_confirmation"
    t.string "tracking_carrier_pro"
    t.boolean "truckload", default: false
    t.datetime "updated_at", precision: nil
    t.bigint "updated_by_id"
    t.integer "value_cents", default: 0, null: false
    t.string "value_currency", default: "USD", null: false
    t.index ["applied_rate_id"], name: "index_shipments_on_applied_rate_id"
    t.index ["broker_customer_id"], name: "index_shipments_on_broker_customer_id"
    t.index ["broker_notes"], name: "index_shipments_on_broker_notes"
    t.index ["created_by_id"], name: "index_shipments_on_created_by_id"
    t.index ["dispatcher_id"], name: "index_shipments_on_dispatcher_id"
    t.index ["load_id"], name: "index_shipments_on_load_id", unique: true
    t.index ["receiver_address_id"], name: "index_shipments_on_receiver_address_id"
    t.index ["shipper_address_id"], name: "index_shipments_on_shipper_address_id"
    t.index ["status"], name: "index_shipments_on_status"
    t.index ["tracking_carrier_id"], name: "index_shipments_on_tracking_carrier_id"
    t.index ["updated_by_id"], name: "index_shipments_on_updated_by_id"
  end

  create_table "standardized_addresses", force: :cascade do |t|
    t.integer "addresses_count"
    t.string "city"
    t.string "country_alpha2", limit: 2, null: false
    t.datetime "created_at", null: false
    t.text "google_places_spot_cached"
    t.datetime "google_places_spot_updated_at", precision: nil
    t.string "key"
    t.string "latitude"
    t.string "longitude"
    t.text "open_street_map_result_cached"
    t.datetime "open_street_map_result_updated_at", precision: nil
    t.string "postal_code"
    t.string "region_iso31662", null: false
    t.text "smarty_streets_result_cached"
    t.datetime "smarty_streets_result_updated_at", precision: nil
    t.string "street"
    t.string "street2"
    t.string "time_zone_name", null: false
    t.datetime "updated_at", null: false
    t.index ["country_alpha2"], name: "index_standardized_addresses_on_country_alpha2"
    t.index ["key"], name: "index_standardized_addresses_on_key"
    t.index ["region_iso31662"], name: "index_standardized_addresses_on_region_iso31662"
  end

  create_table "stripe_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encrypted_account_id"
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "canceled_at"
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["canceled_at"], name: "index_subscriptions_on_canceled_at"
    t.index ["contact_id", "record_id", "record_type"], name: "index_subscriptions_on_contact_id_and_record_id_and_record_type", unique: true
    t.index ["contact_id"], name: "index_subscriptions_on_contact_id"
    t.index ["record_type", "record_id"], name: "index_subscriptions_on_record"
  end

  create_table "suppressions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ignored_at"
    t.bigint "ignored_by_id"
    t.bigint "instigator_id", null: false
    t.string "instigator_type", null: false
    t.bigint "problem_id", null: false
    t.bigint "problematic_id", null: false
    t.string "problematic_type", null: false
    t.string "suppressible_type", null: false
    t.bigint "suppressor_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ignored_by_id"], name: "index_suppressions_on_ignored_by_id"
    t.index ["instigator_type", "instigator_id"], name: "index_suppressions_on_instigator"
    t.index ["problem_id"], name: "index_suppressions_on_problem_id"
    t.index ["problematic_type", "problematic_id"], name: "index_suppressions_on_problematic"
    t.index ["suppressible_type"], name: "index_suppressions_on_suppressible_type"
    t.index ["suppressor_id"], name: "index_suppressions_on_suppressor_id"
  end

  create_table "suppressors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "instigator_id", null: false
    t.string "instigator_type", null: false
    t.string "problematic_rule_code", null: false
    t.string "problematic_type", null: false
    t.string "suppressible_type", null: false
    t.datetime "updated_at", null: false
    t.index ["instigator_type", "instigator_id"], name: "index_suppressors_on_instigator"
    t.index ["problematic_rule_code"], name: "index_suppressors_on_problematic_rule_code"
    t.index ["problematic_type"], name: "index_suppressors_on_problematic_type"
    t.index ["suppressible_type"], name: "index_suppressors_on_suppressible_type"
  end

  create_table "terminals", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.bigint "carrier_id", null: false
    t.datetime "created_at", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_terminals_on_address_id"
    t.index ["carrier_id"], name: "index_terminals_on_carrier_id"
  end

  create_table "tracking_events", force: :cascade do |t|
    t.bigint "address_id"
    t.text "api_request"
    t.text "api_response"
    t.datetime "at", precision: nil
    t.string "city"
    t.string "country_alpha2", limit: 2
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.string "freight_kit_carrier_fingerprint"
    t.boolean "public", default: true
    t.string "region_iso31662"
    t.bigint "shipment_id", null: false
    t.bigint "terminal_id"
    t.string "time_zone_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["address_id"], name: "index_tracking_events_on_address_id"
    t.index ["country_alpha2"], name: "index_tracking_events_on_country_alpha2"
    t.index ["event_id"], name: "index_tracking_events_on_event_id"
    t.index ["region_iso31662"], name: "index_tracking_events_on_region_iso31662"
    t.index ["shipment_id"], name: "index_tracking_events_on_shipment_id"
    t.index ["terminal_id"], name: "index_tracking_events_on_terminal_id"
    t.index ["user_id"], name: "index_tracking_events_on_user_id"
  end

  create_table "upcharge_rules", force: :cascade do |t|
    t.bigint "broker_customer_id", null: false
    t.datetime "created_at", null: false
    t.integer "max"
    t.integer "min"
    t.bigint "packaging_id", null: false
    t.integer "upcharge_cents", default: 0, null: false
    t.string "upcharge_currency", default: "USD", null: false
    t.float "upcharge_percentage", default: 0.0
    t.datetime "updated_at", null: false
    t.index ["broker_customer_id"], name: "index_upcharge_rules_on_broker_customer_id"
    t.index ["packaging_id"], name: "index_upcharge_rules_on_packaging_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.bigint "companyable_id"
    t.string "companyable_type"
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.bigint "contact_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.boolean "deactivated", default: false
    t.string "email", default: "", null: false
    t.text "email_notifications_blacklist"
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.datetime "invitation_accepted_at", precision: nil
    t.datetime "invitation_created_at", precision: nil
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at", precision: nil
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.bigint "invited_by_id"
    t.string "last_name"
    t.datetime "last_sign_in_at", precision: nil
    t.inet "last_sign_in_ip"
    t.datetime "locked_at", precision: nil
    t.string "phone"
    t.boolean "receive_email_notifications", default: true
    t.boolean "receive_notifications_from_self", default: true
    t.boolean "receive_read_notifications_by_email", default: false
    t.boolean "receive_sms_notifications"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "time_zone_name", null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["companyable_type", "companyable_id"], name: "index_users_on_companyable"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["contact_id"], name: "index_users_on_contact_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "standardized_addresses"
  add_foreign_key "broker_accessorials", "accessorials"
  add_foreign_key "broker_accessorials", "broker_customers"
  add_foreign_key "broker_carriers", "addresses", column: "check_mailing_address_id"
  add_foreign_key "broker_carriers", "broker_customers"
  add_foreign_key "broker_carriers", "carriers"
  add_foreign_key "broker_customer_dispatchers", "broker_customers"
  add_foreign_key "broker_customer_dispatchers", "users"
  add_foreign_key "broker_customer_sales_reps", "broker_customers"
  add_foreign_key "broker_customer_sales_reps", "users"
  add_foreign_key "broker_customers", "addresses", column: "office_address_id"
  add_foreign_key "broker_customers", "addresses", column: "primary_pickup_address_id"
  add_foreign_key "broker_customers", "contacts", column: "receivables_contact_id"
  add_foreign_key "broker_customers", "customers"
  add_foreign_key "carrier_areas", "areas", column: "from_area_id"
  add_foreign_key "carrier_areas", "areas", column: "to_area_id"
  add_foreign_key "carrier_areas", "carriers"
  add_foreign_key "carriers", "addresses", column: "broker_billing_address_id"
  add_foreign_key "carriers", "addresses", column: "check_mailing_address_id"
  add_foreign_key "claim_items", "claims"
  add_foreign_key "claims", "shipments"
  add_foreign_key "comments", "contacts"
  add_foreign_key "comments", "discussion_topics"
  add_foreign_key "commissions", "shipments"
  add_foreign_key "commissions", "users"
  add_foreign_key "contact_roles", "contacts"
  add_foreign_key "document_preferences", "broker_customers"
  add_foreign_key "document_preferences", "contacts"
  add_foreign_key "integration_mappings", "integrations"
  add_foreign_key "items", "shipments"
  add_foreign_key "location_areas", "areas"
  add_foreign_key "location_areas", "locations"
  add_foreign_key "overlength_rules", "broker_carriers"
  add_foreign_key "payment_transactions", "broker_carriers"
  add_foreign_key "payment_transactions", "payments"
  add_foreign_key "payment_transactions", "shipments"
  add_foreign_key "payment_transactions", "users", column: "created_by_id"
  add_foreign_key "payments", "banks"
  add_foreign_key "payments", "broker_carriers"
  add_foreign_key "payments", "payment_methods"
  add_foreign_key "payments", "users", column: "approved_by_id"
  add_foreign_key "payments", "users", column: "created_by_id"
  add_foreign_key "pickups", "rates"
  add_foreign_key "pickups", "shipments"
  add_foreign_key "pickups", "users", column: "dispatcher_id"
  add_foreign_key "pickups", "users", column: "updated_by_id"
  add_foreign_key "preferred_broker_carriers", "broker_carriers"
  add_foreign_key "preferred_broker_carriers", "broker_customers"
  add_foreign_key "pricing_rules", "broker_carriers"
  add_foreign_key "pricing_rules", "carrier_areas"
  add_foreign_key "problems", "users", column: "assigned_to_id"
  add_foreign_key "problems", "users", column: "resolved_by_id"
  add_foreign_key "rate_accessorials", "accessorials"
  add_foreign_key "rate_accessorials", "rates"
  add_foreign_key "rates", "broker_carriers"
  add_foreign_key "rates", "broker_customers"
  add_foreign_key "rates", "carriers", column: "tracking_carrier_id"
  add_foreign_key "rates", "shipments"
  add_foreign_key "receivable_items", "receivables"
  add_foreign_key "receivables", "shipments"
  add_foreign_key "receivables", "users", column: "authorized_by_id"
  add_foreign_key "receivables", "users", column: "created_by_id"
  add_foreign_key "receivables", "users", column: "sent_by_id"
  add_foreign_key "receivables", "users", column: "updated_by_id"
  add_foreign_key "shipment_accessorials", "accessorials"
  add_foreign_key "shipment_accessorials", "shipments"
  add_foreign_key "shipment_broker_accessorials", "broker_accessorials"
  add_foreign_key "shipment_broker_accessorials", "shipments"
  add_foreign_key "shipments", "addresses", column: "receiver_address_id"
  add_foreign_key "shipments", "addresses", column: "shipper_address_id"
  add_foreign_key "shipments", "broker_customers"
  add_foreign_key "shipments", "carriers", column: "tracking_carrier_id"
  add_foreign_key "shipments", "rates", column: "applied_rate_id"
  add_foreign_key "shipments", "users", column: "created_by_id"
  add_foreign_key "shipments", "users", column: "dispatcher_id"
  add_foreign_key "shipments", "users", column: "updated_by_id"
  add_foreign_key "subscriptions", "contacts"
  add_foreign_key "suppressions", "problems"
  add_foreign_key "suppressions", "suppressors"
  add_foreign_key "suppressions", "users", column: "ignored_by_id"
  add_foreign_key "terminals", "addresses"
  add_foreign_key "terminals", "carriers"
  add_foreign_key "tracking_events", "addresses"
  add_foreign_key "tracking_events", "events"
  add_foreign_key "tracking_events", "shipments"
  add_foreign_key "tracking_events", "terminals"
  add_foreign_key "tracking_events", "users"
  add_foreign_key "upcharge_rules", "broker_customers"
  add_foreign_key "upcharge_rules", "packagings"
  add_foreign_key "users", "contacts"
  add_foreign_key "users", "users", column: "invited_by_id"
end
