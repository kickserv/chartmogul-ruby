# frozen_string_literal: true

module ChartMogul
  class SubscriptionEvent < APIResource
    set_resource_name 'SubscriptionEvent'
    set_resource_path '/v1/subscription_events'

    readonly_attr :id
    writeable_attr :data_source_uuid
    writeable_attr :customer_external_id
    writeable_attr :subscription_set_external_id
    writeable_attr :subscription_external_id
    writeable_attr :plan_external_id
    writeable_attr :event_date
    writeable_attr :effective_date
    writeable_attr :event_type
    writeable_attr :external_id
    readonly_attr :errors
    readonly_attr :created_at
    readonly_attr :updated_at
    writeable_attr :quantity
    writeable_attr :currency
    writeable_attr :amount_in_cents
    writeable_attr :tax_amount_in_cents
    writeable_attr :retracted_event_id

    include API::Actions::Custom
    include API::Actions::DestroyWithParams

    def self.all(options = {})
      SubscriptionEvents.all(options)
    end

    def create!
      custom!(:post, resource_path.path, subscription_event: instance_attributes)
    end

    def update!(attrs)
      custom!(:patch, resource_path.path, subscription_event: attrs.merge(id: instance_attributes[:id]))
    end

    def destroy!
      handling_errors do
        connection.delete(resource_path.path, subscription_event: { id: instance_attributes[:id] })
      end
    end
  end

  class SubscriptionEvents < APIResource
    set_resource_name 'SubscriptionEvents'
    set_resource_path '/v1/subscription_events'

    set_resource_root_key :subscription_events

    writeable_attr :meta

    include API::Actions::All
    include Concerns::Entries

    set_entry_class SubscriptionEvent
  end
end
