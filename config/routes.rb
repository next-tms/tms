Rails.application.routes.draw do

  root 'welcome#index'

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

  devise_for :users
  as :user do
    get 'users/edit' => 'devise/registrations#edit', as: 'edit_user_registration'    
    put 'users' => 'devise/registrations#update', as: 'user_registration'            
  end

  get 'contact-card', to: 'brokers#contact_card'
  get 'tracking' => 'tracking#show'

  namespace :broker do
    root 'shipments#index'

    get 'customers/profitability-report' => 'broker_customers#profitability_report'
    get 'customers/:id/shipments' => 'broker_customers#shipments', as: :broker_customer_shipments
    resources :broker_customers, path: 'customers' do
      member { get 'carriers' => 'broker_customers#broker_carriers', as: :broker_carriers }
      member { get 'carriers/edit' => 'broker_customers#edit_broker_carriers', as: :edit_broker_carriers }
      member { get 'pricing' => 'broker_customers#pricing', as: :pricing }
      member { get 'pricing/edit' => 'broker_customers#edit_pricing', as: :edit_pricing }
      member { get 'sales-reps' => 'broker_customers#sales_reps', as: :sales_reps }
    end

    resources :broker_carriers, path: 'carriers' do
      member { get 'tariff' => 'broker_carriers#tariff', as: :tariff }
      member { get 'terminals/search' => 'broker_carriers#search_terminals', as: :search_terminals }
    end

    resources :contacts

    get 'ap/invoices/import', to: 'payment_transactions#import'
    post 'ap/invoices/import', to: 'payment_transactions#import_create'

    resources :payment_transactions, path: 'ap/invoices' do
    end

    get 'ap/payments/overdue', to: 'payments#overdue'
    get 'ap/payments/paid', to: 'payments#paid'

    get 'ap/payments/import-legacy', to: 'payments#import_legacy'
    post 'ap/payments/import-legacy', to: 'payments#create'

    resources :payments, path: 'ap/payments' do
      member { get 'pay', as: :pay }
    end

    get 'settings', to: 'broker#settings', as: :settings
    resources :broker_accessorials, path: 'settings/accessorials'

    resources :payments

    get 'shipments/pending-dispatch', to: 'shipments#pending_dispatch'
    get 'shipments/late', to: 'shipments#late'
    get 'shipments/pending-found', to: 'shipments#pending_found'
    get 'shipments/delivered', to: 'shipments#delivered'
    get 'shipments/missing-delivery-appointment', to: 'shipments#missing_delivery_appointment'
    get 'shipments/missing-pricing', to: 'shipments#missing_pricing'
    get 'shipments/missing-pro', to: 'shipments#missing_pro'
    get 'shipments/pending-delivery', to: 'shipments#pending_delivery'
    get 'shipments/pending-departure', to: 'shipments#pending_departure'
    get 'shipments/pending-pickup', to: 'shipments#pending_pickup'
    get 'shipments/pending-quotation', to: 'shipments#pending_quotation'

    get 'shipments/quote-only' => 'shipments#new_quote_only', as: :quote_only
    resources :shipments, path: 'shipments', as: :shipments, param: :load_id do
      # Stupid, but required for some AJAX without PATCH
      get 'update' => 'shipments#update', as: :update
      member { get 'documents' => 'shipments#documents', as: :documents }
      member { get 'documents/bol' => 'shipments#documents_bol', as: :bol_document }
      member { get 'documents/quote' => 'shipments#documents_quote', as: :quote_document }
      member { get 'notes', as: :notes }
      member { get 'pricing', as: :pricing }
      member { get 'quote', as: :quote }
      member { get 'transit', as: :transit }
      member { get 'tracking', as: :tracking_events, to: 'shipments#tracking_events' }
      member { get 'tracking/edit', as: :edit_tracking_events, to: 'shipments#edit_tracking_events' }
      member { get 'tracking/update', as: :update_tracking_events, to: 'shipments#update_tracking_events' }
      member { post 'tracking/create', as: :create_tracking_event, to: 'shipments#create_tracking_event' }
    end

    get 'search' => 'search#search'
  end

  namespace :customer do
    root 'shipments#index'
    get 'shipments/quote-only' => 'shipments#new_quote_only', as: :quote_only
    resources :shipments, path: 'shipments', as: :shipments, param: :load_id, only: [:index, :new, :create, :edit, :show, :update] do
      member { get 'documents' => 'shipments#documents', as: :documents }
      member { get 'documents/bol' => 'shipments#documents_bol', as: :bol_document }
      member { get 'documents/quote' => 'shipments#documents_quote', as: :quote_document }
      member { get 'quote', as: :quote }
    end
    get 'search' => 'search#search'
  end

end