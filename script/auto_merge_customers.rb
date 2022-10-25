require 'chartmogul'
require 'csv'
require 'json'

ChartMogul.global_api_key = '0904375ecd7aec1be3de69d48d59c197'

# chargify_ds_uuid = 'ds_a855416a-39bf-11ed-aab8-1f5c580ac43d'
# stripe_ds_uuid = 'ds_067bfee8-385b-11ed-89b6-eb111e062d68' # may not need the ds prefix?


rows = []

# A file named 'data.CSV' must exist with 2 column headers.
# The columns should be filled with the UUIDs of the two customers being merged.

# Example data.CSV:
# from_uuid,into_uuid
# cus_3hs8fh_sh4n3s,cus_38dj220_2n2du

CSV.foreach('kickserve_merge_full.csv', headers: true, converters: :all) do |row|
  rows << row.to_hash
end

rows.each { |row|
	puts "Merging email #{row['email']}"
	# Start merge ---

	begin
		from_customer = ChartMogul::Customer.retrieve(row["from_uuid"])
		into_customer = ChartMogul::Customer.retrieve(row["into_uuid"])	
	rescue => exception
		puts "Couldn't find customer"
		next
	end

	puts "Merging #{from_customer.name} into #{into_customer.name}"
	
	begin
		from_customer.merge_into!(into_customer) 
	rescue => e 
		puts "Error during merge for customer #{row['email']}"
		next
	end

	# End merge ---
	puts row["into_uuid"]

}
