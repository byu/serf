require 'factory_girl'
require 'hashie'
require 'securerandom'

FactoryGirl.define do
  sequence(:random_string) { SecureRandom.hex }

  factory :empty_parcel, class: Hashie::Mash do
    headers {{
    }}
    message {{
    }}
  end

  factory :random_parcel, class: Hashie::Mash do
    headers {{
      uuid: generate(:random_string),
      origin_uuid: generate(:random_string),
      parent_uuid: generate(:random_string),
      kind: generate(:random_string)
    }}
    message {{
      some_data: generate(:random_string)
    }}
  end

  factory :random_headers, class: Hashie::Mash do
    uuid { generate(:random_string) }
    origin_uuid { generate(:random_string) }
    parent_uuid { generate(:random_string) }
    kind { generate(:random_string) }
    option_a { generate(:random_string) }
  end

  factory :random_message, class: Hashie::Mash do
    data { generate(:random_string) }
  end

  factory :random_options, class: Hashie::Mash do
    option_a { generate(:random_string) }
    option_b { generate(:random_string) }
    option_c { generate(:random_string) }
  end
end
