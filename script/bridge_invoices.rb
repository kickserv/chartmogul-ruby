require 'awesome_print'
require 'chartmogul'
require 'csv'
# require 'json'

ChartMogul.global_api_key = '0904375ecd7aec1be3de69d48d59c197'
CHARGIFY_DS_UUID = 'ds_a855416a-39bf-11ed-aab8-1f5c580ac43d'
# stripe_ds_uuid = 'ds_067bfee8-385b-11ed-89b6-eb111e062d68' # may not need the ds prefix?

def create_bridge_subscriptions
  rows = []

  # A file named 'bridge.CSV' must exist with column headers.
  # The columns should be filled with the UUIDs of the customers that need a bridge invoice.

  # load the list
  CSV.foreach('prepaid.csv', headers: true, converters: :all) do |row|
    rows << row.to_hash
  end

  rows.each do |row|
    # puts "Customer UUID #{row['uuid']}"
    puts "Customer email: #{row['email']}"

    customers = ChartMogul::Customer.search(row['email'])
    if customers.count < 1
      puts "Found #{customers.count} customers, need to merge"
      # merge 'em
    else
      customer = ChartMogul::Customer.search(row['email']).first
    end
    
    return unless customer
    ap customer.uuid

    plan = row['plan'].downcase || nil
    puts "Prepaid for #{plan}: #{row['amount']}"
    
    start_date = Date.strptime(row['date'], '%m/%d/%Y') #rescue nil
    puts "Migrated on #{start_date}"

    amount = Float(row['amount']) rescue nil
    puts "Prepaid #{(amount *100).to_i} in cents"

    create_bridge_subscription_for customer, plan, start_date, amount
  end
end

def create_bridge_subscription_for(customer, plan, bridge_start_date, amount)
  # prepayment = prepayment_invoice_for(customer)
  
  # if prepayment.nil?
  #   puts "No prepayment found"
  #   return
  # end

  puts "Adding bridge subscription for #{customer.name}"
  
  # amount of last transaction
  # bridge_amount_in_cents = prepayment.line_items.first.amount_in_cents
  bridge_amount_in_cents = (amount * 100).to_i

  bridge_end_date = bridge_start_date.next_year
  
  puts "Start date: #{bridge_start_date}"
  puts "End date: #{bridge_end_date}"

  # plan they migrated to
  # bridge_plan_name = if plan.empty?
  #   parse_plan_from_description(prepayment.line_items.first.description)
  # else
  #   plan.downcase
  # end

  bridge_plan_name = "#{plan.downcase}-prepaid"
  
  bridge_plan_uuid = plan_uuid(bridge_plan_name)
  
  if bridge_plan_uuid.nil?
    puts "Couldn't find new plan"  # from desc '#{prepayment.line_items.first.description}'"
    return
  end

  puts "Plan is #{bridge_plan_name} - #{bridge_plan_uuid}"

  # id of bridge invoice and item
  bridge_id = "bridge_#{customer.id}"

  puts "Creating invoice and subscription with id #{bridge_id}"
    # create invoice line item:
    #   - previously generated id
    #   - amount
    #   - 1 year term
    #   - not prorated
    #   - <plan they migrated to>-prepaid

    # puts "Start: #{bridge_start_date}, end: #{bridge_end_date}"

    line_item = ChartMogul::LineItems::Subscription.new(
      subscription_external_id: bridge_id,
      plan_uuid: bridge_plan_uuid,
      prorated: false,
      service_period_start: bridge_start_date, #Time.utc(2016, 3, 16, 12, 00, 00),
      service_period_end: bridge_end_date, #Time.utc(2016, 4, 1),
      amount_in_cents: bridge_amount_in_cents,
      quantity: 1
    )

  # create invoice using bridge_id
  # need a Chargify customer id
  # Chargify id is numeric; Stripe has a `cus_` prefix
  chargify_id = customer.external_ids.select { |id| id.to_i > 0 }.first
  
  #  - migration date
  
  invoice = ChartMogul::Invoice.new(
    external_id: bridge_id,
    date: bridge_start_date,
    currency: 'USD',
    customer_external_id: chargify_id,
    data_source_uuid: CHARGIFY_DS_UUID,
    line_items: [ line_item ]
    # transactions: [transaction]
  )

  ChartMogul::CustomerInvoices.create!(
    customer_uuid: customer.uuid, 
    invoices: [invoice])
  
  # add the `connected` tag
  customer.add_tags! 'connected'
end

# LOCK IN SELECTOR
# Returns an invoice for an annual lock-in payment.
# Looks for a one-time invoice created after 7/1/22 containing a line item with "lock" in the description.
def prepayment_invoice_for(customer)
  invoice = customer.invoices.select { |inv| 
    inv.line_items.any? { |i| i.type == 'one_time' && i.description.downcase.include?('lock') }
  }.first

  invoice if invoice && invoice.date > Time.parse('2022-07-01')
end

def parse_plan_from_description(desc)
  desc.downcase!
  
  found_plan = %w{ lite standard business premium }.inject('') do |result, plan|
    result = plan if desc.include?(plan) 
    result
  end 
  
  found_plan += '-prepaid' unless found_plan.empty?
end

def plan_uuid(plan_name)
  plans = {
    'lite-prepaid' => 'pl_c7ca6322-4423-11ed-8289-1b0661c76c71',
    'standard-prepaid' => 'pl_3074acbc-43f6-11ed-ab7b-179db34f8e67',
    'business-prepaid' => 'pl_ef6ce5b6-43f7-11ed-9767-1bd1b969424f',
    'premium-prepaid' => 'pl_b5f60f66-4423-11ed-9698-e7d6d8728aff'
  }

  plans[plan_name]
end

create_bridge_subscriptions
