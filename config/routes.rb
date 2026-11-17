Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root 'welcome#index'

  get '/graphiql', to: 'graphiql#show'
  post '/graphql', to: 'graphql#execute', as: :graphql, defaults: { format: :json }
  post '/mcp', to: 'mcp#create', as: :mcp, defaults: { format: :json }
  match '/mcp', to: ->(_env) { [405, { 'allow' => 'POST' }, []] }, via: %i[delete get]

  get '.well-known/api-catalog', to: 'well_known/api_catalogs#show', as: :api_catalog, defaults: { format: :json }, format: false
  get 'llms.txt', to: 'llms_texts#show', as: :llms_text, defaults: { format: :text }, format: false
  get 'skills/tms/SKILL.md', to: 'skills#show', as: :skill, defaults: { format: :md }, format: false

  devise_for :users, controllers: { invitations: 'users/invitations', registrations: 'users/registrations' }

  as :user do
    get 'users/edit' => 'users/registrations#edit', as: 'edit_user_registration'
    put 'users' => 'users/registrations#update', as: 'user_registration'
  end

  get 'contact-card', to: 'brokers#contact_card'
  get 'tracking' => 'tracking#show'

  post 'fetch_details_by_zip_code', to: 'geocoder#fetch_details_by_zip_code', defaults: { format: :json }
  post 'fetch_address_by_broker_customer', to: 'geocoder#fetch_address_by_broker_customer', defaults: { format: :json }
  post 'validate_address', to: 'geocoder#validate_address', defaults: { format: :json }

  AccountingConnectionsController::PROVIDERS.each do |kind, slug|
    get "gateway/accounts/#{slug}/authenticate", as: :"connect_#{kind}_accounting", to: 'accounting_connections#connect',
                                                 defaults: { kind: }
    get "gateway/accounts/#{slug}/oauth-callback", as: :"oauth_callback_#{kind}_accounting", to: 'accounting_connections#callback',
                                                   defaults: { kind: }
  end

  resources :api_keys, only: %i[create destroy index new show], path: 'account/api-keys' do
    collection do
      get :active
      get :expired
    end

    resource :roll, only: %i[create], module: :api_keys
  end

  resources :notifications, only: %i[show index]

  namespace :broker do
    get 'customers/profitability-report' => 'broker_customers#profitability_report'
    get 'customers/:id/receivables' => 'broker_customers#receivables', as: :broker_customer_receivables
    get 'customers/:id/shipments' => 'broker_customers#shipments', as: :broker_customer_shipments

    get 'settings/company', to: 'broker#settings'
    resources :broker_countries, only: %i[create destroy], path: 'settings/company/countries'
    resources :broker_accessorials, path: 'settings/company/accessorials'

    get 'settings/company/accounting', to: 'accounting#show'

    resources :broker_customers, path: 'customers' do
      collection do
        get :accounting
        patch :accounting, to: 'broker_customers#update_accounting'
      end

      # TODO: Tidy this up
      member { get 'carriers' => 'broker_customers#broker_carriers', as: :broker_carriers }
      member { get 'carriers/edit' => 'broker_customers#edit_broker_carriers', as: :edit_broker_carriers }
      member { get 'contacts' => 'broker_customers#contacts', as: :contacts }
      member { get 'pricing' => 'broker_customers#pricing', as: :pricing }
      member { patch 'pricing/update' => 'broker_customers#update_pricing', as: :update_pricing }
      member { get 'pricing/edit' => 'broker_customers#edit_pricing', as: :edit_pricing }
      member { get 'primary-pickup-address' => 'broker_customers#primary_pickup_address', as: :primary_pickup_address }
      member { get 'sales-reps' => 'broker_customers#sales_reps', as: :sales_reps }
    end

    resources :broker_customer_sales_reps, path: 'sales-reps' do
      member { get 'commissions' => 'broker_customer_sales_reps#commissions', as: :commissions }
    end

    namespace :carriers do
      resource :accounting, only: %i[show update]
    end

    resources :carriers, only: %i[create index new show] do
      scope module: :carriers do
        resources :api_keys, only: %i[create destroy index new show], path: 'api-keys' do
          resource :roll, module: :api_keys, only: %i[create]
        end

        resources :broker_carriers, except: %i[destroy], path: 'accounts' do
          scope module: :broker_carriers do
            resources :payment_transactions, only: %i[index], path: 'bills'
            resources :payments, only: %i[index]
            resources :shipments, only: %i[index]

            resource :tariff, only: %i[show update]
          end
        end

        resources :contacts, only: %i[index]
        resources :payment_transactions, only: %i[index], path: 'bills'
        resources :payments, only: %i[index]
        resources :shipments, only: %i[index]
        resources :terminals, only: %i[index]
        resources :users, only: %i[index]
      end
    end

    resources :claims do
      collection { get :paid }
      collection { get :unpaid }
    end

    resources :contacts, except: %i[index]

    resources :banks, except: %i[destroy], path: 'bank-accounts' do
      collection do
        get :accounting
        patch :accounting, to: 'banks#update_accounting'
      end

      member { get 'activity', to: 'banks#activity' }
    end

    get 'rates/:uid/breakdown-modal', as: 'rate_breakdown_modal', to: 'rates#breakdown_modal'

    resources :payment_transactions, path: 'bills' do
      collection do
        get :due
        get :import
        get :overdue
        get :paid
        get 'import-sample-csv'
      end
    end

    resources :payments do
      collection do
        get :due
        get :paid
        get :overdue
      end

      member { get :pay }
    end
    post 'payment/due_payment_transactions', to: 'payments#due_payment_transactions', defaults: { format: :json }

    resources :receivables, path: 'receivables' do
      collection { get :authorized }
      collection { get :invoiced }
      collection { get :paid }
      collection { get :unauthorized }
      member { get 'rebuild', as: :rebuild }
    end

    resources :pickups, only: %i[create]
    get 'pickups', to: 'pickups#create' # used by Broker::ShipmentsControlller

    resources :problems, except: %i[destroy], path: 'tasks' do
      collection do
        get :resolved
        get :suppressive
        get :team
        get :yours
      end
    end

    resources :settings

    get 'shipments/booked', to: 'shipments#booked'
    get 'shipments/pending-dispatch', to: 'shipments#pending_dispatch'
    get 'shipments/late', to: 'shipments#late'
    get 'shipments/pending-found', to: 'shipments#pending_found'
    get 'shipments/delivered', to: 'shipments#delivered'
    get 'shipments/missing-delivery-appointment', to: 'shipments#missing_delivery_appointment'
    get 'shipments/missing-pricing', to: 'shipments#missing_pricing'
    get 'shipments/missing-pro', to: 'shipments#missing_pro'
    get 'shipments/pending-delivery', to: 'shipments#pending_delivery'
    get 'shipments/pending-delivery/late', to: 'shipments#pending_delivery_late'
    get 'shipments/pending-delivery/on-time', to: 'shipments#pending_delivery_on_time'
    get 'shipments/pending-delivery/without-delivery-eta-on', to: 'shipments#pending_delivery_without_delivery_eta_on'
    get 'shipments/pending-departure', to: 'shipments#pending_departure'
    get 'shipments/pending-pickup', to: 'shipments#pending_pickup'
    get 'shipments/pending-pickup/late', to: 'shipments#pending_pickup'
    get 'shipments/pending-pickup/today', to: 'shipments#pending_pickup_today'
    get 'shipments/pending-pickup/future', to: 'shipments#pending_pickup_future'
    get 'shipments/pending-quotation', to: 'shipments#pending_quotation'
    get 'shipments/as_dispatcher', to: 'shipments#as_dispatcher'

    get 'shipments/quote-only' => 'shipments#new_quote_only', as: :quote_only

    resources :shipments, path: 'shipments', as: :shipments, param: :load_id do
      # Stupid, but required for some AJAX without PATCH
      get 'update' => 'shipments#update', as: :update

      resource :tracking_events, module: :shipments, only: %i[edit show update], path: 'tracking'

      member do
        get :accounting
        get :book
        get :claims
        get :documents
        get :history
        get :notes
        get :pricing
        get :quote
        get :transit
        get :unbook
        get 'book-modal'
        get 'documents/send/:shipment_method', to: 'shipments#send_document', as: :send_document
        get 'pickup-modal'

        patch 'update-transit'
        patch 'upload-document'

        post :duplicate
        post 'documents/send/:active_storage_blob_id',
             to: 'shipments#send_document_with_contact_mailer',
             as: :send_document_with_contact_mailer
      end
    end

    get 'search' => 'search#search'

    resources :users do
      collection { delete 'stop-impersonating' }
      member { post :impersonate }
    end
  end

  namespace :carrier do
    root 'broker_carriers#index'

    resources :broker_carriers, only: %i[index], path: '' do
      resources :shipments, only: %i[index]
    end
  end

  namespace :customer do
    root 'shipments#index'

    resources :receivables, only: %i[index show], path: 'invoices' do
      collection { get :invoiced }
      collection { get :paid }
    end

    get 'shipments/booked', to: 'shipments#booked'
    get 'shipments/delivered', to: 'shipments#delivered'
    get 'shipments/pending-delivery', to: 'shipments#pending_delivery'
    get 'shipments/pending-dispatch', to: 'shipments#pending_dispatch'
    get 'shipments/pending-pickup', to: 'shipments#pending_pickup'
    get 'shipments/pending-quotation', to: 'shipments#pending_quotation'
    get 'shipments/quote-only' => 'shipments#new_quote_only', as: :quote_only
    resources :shipments, path: 'shipments', as: :shipments, param: :load_id, only: %i[index new create edit show update] do
      member { get 'book' => 'shipments#book', as: :book }
      member { get 'documents' => 'shipments#documents', as: :documents }
      member { get 'documents/bol' => 'shipments#documents_bol', as: :bol_document }
      member { get 'documents/quote' => 'shipments#documents_quote', as: :quote_document }
      member { get 'quote', as: :quote }
      member { get 'unbook' => 'shipments#unbook', as: :unbook }
    end
    get 'search' => 'search#search'
  end

  resources :countries, only: %i[show]

  scope as: :broker_ware, defaults: { format: :json }, format: false, module: :broker_ware do
    post 'connect/token', to: 'tokens#create'

    scope path: 'api/v1' do
      get 'accessorial', to: 'accessorials#index'
      post 'CancelShipment', to: 'shipments#destroy'
      post 'createshipment', to: 'shipments#create'
      get 'GetLoads', to: 'shipments#index'
      get 'invoice', to: 'invoices#index'
      get 'Invoice/customfields', to: 'invoices#index', defaults: { custom_fields: true }
      get 'ListShipmentDocuments', to: 'documents#index', defaults: { names: true }
      get 'LoadDocsbyURL', to: 'documents#index'
      get 'ProductList', to: 'products#index'
      post 'rating', to: 'rates#create'
      post 'RatingWithRateQuoteId', to: 'rates#create', defaults: { breakdown: true }
      post 'SendShipmentDocuments', to: 'document_deliveries#create'
      get 'tracking', to: 'tracking#show'
      post 'UpdateShipment', to: 'shipments#update'
    end
  end

  namespace :dsdc, defaults: { format: :json }, format: false, path: 'api/dsdc' do
    resources :bols, only: %i[create destroy update], param: :pro, path: 'bol/v1/app'
    resources :documents, only: %i[create destroy index show], param: :invoice_number, path: 'v1/documents'
    resources :invoices, only: %i[create destroy index show update], param: :unique_id, path: 'v1/invoices'

    get 'v1/pickups', to: 'pickup_requests#show', as: :pickup_request_lookup
    resources :pickup_requests, only: %i[create destroy update], param: :pickup_id, path: 'v1/pickups'

    get 'shipment/bol/:bol/:origin_postal_code/public', to: 'public_shipments#show'
    get 'shipment/bol/:bol/:origin_postal_code/verified', to: 'shipments#show'
    get 'shipment/po/:account_number/:start_date/:end_date/verified', to: 'shipments#index'
    get 'shipment/po/:po/:destination_postal_code/public', to: 'public_shipments#show'
    get 'shipment/po/:po/:destination_postal_code/verified', to: 'shipments#show'
    get 'shipment/pro/:pro/public', to: 'public_shipments#show'
    get 'shipment/pro/:pro/verified', to: 'shipments#show'
  end

  namespace :freightview, defaults: { format: :json }, format: false, path: 'api/v2.0' do
    resources :ltl_shipments, only: %i[create], path: 'shipments/ltl'
    resources :shipments, only: %i[show], param: :shipment_id
  end
end
