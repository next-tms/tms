namespace :wave do
  desc 'Connect Wave Accounting using a full access token'
  task :connect, [:access_token] => :environment do |_task, args|
    access_token = args.fetch(:access_token) { abort('Usage: rake wave:connect[TOKEN]') }

    integration = Integration.where(kind: :wave).first_or_initialize(name: 'default')
    integration.service.connect_with_token!(access_token:)

    puts "Connected Wave business #{integration.reload.credentials['business_id']}"
  end
end
