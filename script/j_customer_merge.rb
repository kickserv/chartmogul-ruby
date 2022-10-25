require 'chartmogul'
require 'csv'
require 'json'

ChartMogul.global_api_key = '0904375ecd7aec1be3de69d48d59c197'

# chargify_ds_uuid = 'ds_a855416a-39bf-11ed-aab8-1f5c580ac43d'
# stripe_ds_uuid = 'ds_067bfee8-385b-11ed-89b6-eb111e062d68' # may not need the ds prefix?

emails = []
CSV.foreach('customer_emails_only.csv', headers: true, converters: :all) do |row|
	emails << row['email']
end
	
emails = emails.uniq



# rows = []

# A file named 'data.CSV' must exist with 2 column headers.
# The columns should be filled with the UUIDs of the two customers being merged.

# Example data.CSV:
# from_uuid,into_uuid
# cus_3hs8fh_sh4n3s,cus_38dj220_2n2du

# CSV.foreach('data.csv', headers: true, converters: :all) do |row|
#   rows << row.to_hash
# end

emails.each { |row|

	# skip if on the list of exceptions
	next if exclude_customer?(row)

	# Look up
	dupes = ChartMogul::Customer.search(row)

	next if dupes.count < 2

	puts "Merging email #{row}"
	
	# Start merge ---
	from_customer = ChartMogul::Customer.retrieve(row["from_uuid"])
	
	# Use the Stripe one if available
	into_customer = ChartMogul::Customer.retrieve(row["into_uuid"])

	puts "Merging #{from_customer.name} into #{into_customer.name}"
	
	from_customer.merge_into!(into_customer)

	# End merge ---
	puts row["into_uuid"]
}

def exclude_customer?(email)
	return true if email.blank?
	emails_to_exclude = %w{
		apiplumbing.com
		artisanpianos.com
		rogersbiz.com
		wheelsforthewise.com
		cascobayelectric.com
		twinhomeexperts.com
		RainTechSprinklerSolutions.com
		windowanddoorspecialties.com
		1on1technologies.com
		sxresurfacing.com
		plumberz.com
		newpipesinc.com
		flyerview.com
		blackrockautomation.com
		arcstx.com
		yaegerplumbing.com
		callprogressive.com
		thelocalguys.com.au
		heroes.services
		eeg.uk.com
		careformytree.com
		screenmobile-charlotte.com
		canamericadrilling.com
		englandservices.com.au
		horti-tec.com
		sevenmechanical.com
		anorganizedhomeoc@gmail.com
		btfdeanna@gmail.com
		cetaylor914@gmail.com
		pcandrinc@gmail.com
		polarbearheatingair@yahoo.com
	}

	emails_to_exclude.each do |entry|
		return true if email.include?(entry)
	end
	false
end
