require 'awesome_print'
require 'chartmogul'
require 'csv'
require 'json'

ChartMogul.global_api_key = '0904375ecd7aec1be3de69d48d59c197'
# CHARGIFY_DS_UUID = 'ds_a855416a-39bf-11ed-aab8-1f5c580ac43d'
# STRIPE_DS_UUID = 'ds_067bfee8-385b-11ed-89b6-eb111e062d68' # may not need the ds prefix?

@emails_to_skip = [ ]

def connect_subscriptions
  puts "Loading emails of Chargify trials"
  load_emails_with_chargify_trials

  rows = []

  # A file named 'connectable.csv' must exist with column headers.
  # Column headers: date,name,uuid,email,amount,plan,stripe_link,done,notes
  CSV.foreach('connectable.csv', headers: true, converters: :all) do |row|
    rows << row.to_hash
  end

  successes = skips = failures = 0

  rows.each do |row|
    customer = unless row['uuid'].empty?
      ChartMogul::Customer.retrieve(row['uuid'])
    else
      customers = ChartMogul::Customer.search(row['email'])
      
      if customers.count < 1
        puts "Found #{customers.count} customers, need to merge"
        # merge 'em
      else
        customer = ChartMogul::Customer.search(row['email']).first
      end
    end

    return unless customer

    puts "Connecting subscriptions for #{customer.name} - #{customer.uuid}"
    result = connect_subscriptions_for(customer)
    
    case result
    when :connected
      successes += 1
    when :skipped 
      skips += 1
    when :failed
      failures += 1 
    else
      puts "unknown failure: #{result}"
      failures += 1
    end
  end

  puts "Complete!"
  puts "Connected: #{successes}" 
  puts "Failed: #{failures}"
  puts "Skipped: #{skips}"
end

def connect_subscriptions_for(customer)
  puts "Connecting subscriptions for #{customer.name} - #{customer.uuid}"
  
  if skip_customer?(customer)
    puts "Skipped"
    result = :skipped
  else
    result = try_connect customer, customer.subscriptions.to_a
    
    if result == :connected
      puts "Connected!"
      customer.add_tags! 'connected'
    end
  end

  result
end

def try_connect(customer, subscriptions) # subscriptions must be a vanilla array
  return :failed if subscriptions.empty? # No non-trial subscriptions
  return :skipped if subscriptions.count == 1 # Nothing to connect, move along

  puts "Found #{subscriptions.count} subscriptions to connect"

  begin
    subscriptions.shift.connect(customer.uuid, subscriptions)
    return :connected
  rescue ChartMogul::NotFoundError => e
    message = JSON.parse(e.response)['message']
    match = message.match(/UUID (.*) and external ID (.*) cannot/)
    uuid, id = $1, $2

  # Retry the connect
    puts "Removed trial subscription, retrying connect"
    return try_connect customer, remove_trial_chargify_subscription(subscriptions, uuid, id)
  rescue => e
    puts "Unrecoverable error: #{e.message}"
    return :failed
  end

end

def remove_trial_chargify_subscription(subscriptions, ds_uuid, external_id)
  puts "Removing subscription with data source uuid #{ds_uuid} and external id #{external_id}"
  matches = subscriptions.select { |s| s.data_source_uuid == ds_uuid && s.external_id == external_id }
  subscriptions - matches
end

def skip_customer?(customer)
  customer.tags.include?('connected') ||
  @emails_to_skip.include?(customer.email)
end

def load_emails_with_chargify_trials
  # A file named 'connectable.csv' must exist with column headers.
  # # The columns should be filled with the UUIDs of the customers that need subscriptions connected.
  
  emails = []
  
  CSV.foreach('chargify_trials.csv', headers: true, converters: :all) do |row|
    emails << row['email']
  end

  @emails_to_skip = emails
end

connect_subscriptions