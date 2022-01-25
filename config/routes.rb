# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  root 'welcome#index'

  mount Sidekiq::Web => '/sidekiq'

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post 'authenticate', to: 'authentication#authenticate'
      namespace :broker do
        resources :shipments, param: :load_id
      end
      namespace :customer do
        resources :shipments, param: :load_id do
          member { get 'quote', as: :quote }
        end
      end
    end
  end

  devise_for :users, controllers: { invitations: 'users/invitations' }

  as :user do
    get 'users/edit' => 'devise/registrations#edit', as: 'edit_user_registration'
    put 'users' => 'devise/registrations#update', as: 'user_registration'
  end

  get 'contact-card', to: 'brokers#contact_card'
  get 'rates/fetch', to: 'rates_service#fetch'
  get 'tracking' => 'tracking#show'

  get 'gateway/accounts/intuit/authenticate', as: :authenticate_intuit_account, to: 'intuit_accounts#authenticate'
  get 'gateway/accounts/intuit/oauth-callback', as: :oauth_callback_intuit_account, to: 'intuit_accounts#oauth_callback'

  namespace :broker do
    get 'customers/profitability-report' => 'broker_customers#profitability_report'
    get 'customers/:id/receivables' => 'broker_customers#receivables', as: :broker_customer_receivables
    get 'customers/:id/shipments' => 'broker_customers#shipments', as: :broker_customer_shipments

    resources :broker_customers, path: 'customers' do
      member { get 'carriers' => 'broker_customers#broker_carriers', as: :broker_carriers }
      member { get 'carriers/edit' => 'broker_customers#edit_broker_carriers', as: :edit_broker_carriers }
      member { get 'contacts' => 'broker_customers#contacts', as: :contacts }
      member { get 'pricing' => 'broker_customers#pricing', as: :pricing }
      member { get 'pricing/edit' => 'broker_customers#edit_pricing', as: :edit_pricing }
      member { get 'primary-pickup-address' => 'broker_customers#primary_pickup_address', as: :primary_pickup_address }
      member { get 'sales-reps' => 'broker_customers#sales_reps', as: :sales_reps }
    end

    resources :broker_customer_sales_reps, path: 'sales-reps' do
      member { get 'commissions' => 'broker_customer_sales_reps#commissions', as: :commissions }
    end

    get 'carriers/:id/shipments' => 'broker_carriers#shipments', as: :broker_carrier_shipments
    resources :broker_carriers, path: 'carriers' do
      member { get 'contacts' => 'broker_carriers#contacts', as: :contacts }
      member { get 'tariff' => 'broker_carriers#tariff', as: :tariff }
      member { get 'terminals/search' => 'broker_carriers#search_terminals', as: :search_terminals }
    end

    resources :contacts

    resources :banks, except: %i[destroy], path: 'bank-accounts' do
      member { get 'activity', to: 'banks#activity' }
    end

    get 'settings/intuit', to: 'intuit_account#show'

    get 'ap/payments/overdue', to: 'payments#overdue'
    get 'ap/payments/paid', to: 'payments#paid'

    get 'ap/payments/import-legacy', to: 'payments#import_legacy'
    post 'ap/payments/import-legacy', to: 'payments#create'

    resources :payments, path: 'ap/payments' do
      member { get 'pay', as: :pay }
    end

    resources :receivables, path: 'ap/receivables' do
      collection { get :authorized }
      collection { get :invoiced }
      collection { get :paid }
      collection { get :unauthorized }
      member { get 'rebuild', as: :rebuild }
    end

    get 'settings', to: 'broker#settings', as: :settings
    match 'settings', to: 'broker#update', as: :update_settings, via: %i[patch put post]
    resources :broker_accessorials, path: 'settings/accessorials'

    resources :payments
    resources :pickups, only: %i[create]
    get 'pickups', to: 'pickups#create' # used by Broker::ShipmentsControlller

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

    get 'shipments/quote-only' => 'shipments#new_quote_only', as: :quote_only
    resources :shipments, path: 'shipments', as: :shipments, param: :load_id do
      # Stupid, but required for some AJAX without PATCH
      get 'update' => 'shipments#update', as: :update
      member { get 'book' => 'shipments#book', as: :book }
      member { get 'book-modal' => 'shipments#book_modal', as: :book_modal }
      member { get 'documents' => 'shipments#documents', as: :documents }
      member { get 'documents/send/:shipment_method' => 'shipments#send_document', as: :send_document }
      member do
        post 'documents/send/:active_storage_blob_id' => 'shipments#send_document_with_contact_mailer',
             as: :send_document_with_contact_mailer
      end
      member { get 'accounting', as: :accounting }
      member { get 'notes', as: :notes }
      member { get 'pickup-modal', as: :pickup_modal }
      member { get 'pricing', as: :pricing }
      member { get 'quote', as: :quote }
      member { get 'transit', as: :transit }
      member { get 'tracking', as: :tracking_events, to: 'shipments#tracking_events' }
      member { get 'tracking/edit', as: :edit_tracking_events, to: 'shipments#edit_tracking_events' }
      member { get 'tracking/update', as: :update_tracking_events, to: 'shipments#update_tracking_events' }
      member { post 'tracking/create', as: :create_tracking_event, to: 'shipments#create_tracking_event' }
      member { get 'unbook' => 'shipments#unbook', as: :unbook }
    end

    get 'search' => 'search#search'

    resources :users
  end

  namespace :customer do
    root 'shipments#index'

    get 'shipments/booked', to: 'shipments#booked'
    get 'shipments/delivered', to: 'shipments#delivered'
    get 'shipments/pending-delivery', to: 'shipments#pending_delivery'
    get 'shipments/pending-dispatch', to: 'shipments#pending_dispatch'
    get 'shipments/pending-pickup', to: 'shipments#pending_pickup'
    get 'shipments/pending-quotation', to: 'shipments#pending_quotation'
    get 'shipments/quote-only' => 'shipments#new_quote_only', as: :quote_only
    resources :shipments, path: 'shipments', as: :shipments, param: :load_id,
                          only: %i[index new create edit show update] do
      member { get 'book' => 'shipments#book', as: :book }
      member { get 'documents' => 'shipments#documents', as: :documents }
      member { get 'documents/bol' => 'shipments#documents_bol', as: :bol_document }
      member { get 'documents/quote' => 'shipments#documents_quote', as: :quote_document }
      member { get 'quote', as: :quote }
      member { get 'unbook' => 'shipments#unbook', as: :unbook }
    end
    get 'search' => 'search#search'
  end

  resources :countries, only: %(show) do
    member { get 'regions' }
  end
end
