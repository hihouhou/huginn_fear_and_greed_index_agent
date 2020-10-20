module Agents
  class FearAndGreedIndexAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule '1h'

    description do
      <<-MD
      The Fear and Greed index agent fetches fear and greed index for BTC and creates an event by notification.

      `debug` is used to verbose mode.

      `changes_only` is only used to emit event about a status' change.

      `without_timestamp_diff` prevents time_until_update value's change.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:
      {
      	"name": "Fear and Greed Index",
      	"data": [
      		{
      			"value": "55",
      			"value_classification": "Greed",
      			"timestamp": "1602979200",
      			"time_until_update": "50363"
      		}
      	],
      	"metadata": {
      		"error": null
      	}
      }
    MD

    def default_options
      {
        'changes_only' => 'true',
        'debug' => 'false',
        'without_timestamp_diff' => 'true',
        'expected_receive_period_in_days' => '2',
      }
    end

    form_configurable :without_timestamp_diff, type: :boolean
    form_configurable :changes_only, type: :boolean
    form_configurable :debug, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string

    def validate_options

      if options.has_key?('changes_only') && boolify(options['changes_only']).nil?
        errors.add(:base, "if provided, changes_only must be true or false")
      end

      if options.has_key?('without_timestamp_diff') && boolify(options['without_timestamp_diff']).nil?
        errors.add(:base, "if provided, without_timestamp_diff must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def check
      fetch
    end

    private

    def fetch
      uri = URI.parse("https://api.alternative.me/fng/")
      request = Net::HTTP::Get.new(uri)
      request["Authority"] = "api.alternative.me"
      request["Cache-Control"] = "max-age=0"
      request["Upgrade-Insecure-Requests"] = "1"
      request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.99 Safari/537.36"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
      request["Sec-Fetch-Site"] = "none"
      request["Sec-Fetch-Mode"] = "navigate"
      request["Sec-Fetch-User"] = "?1"
      request["Sec-Fetch-Dest"] = "document"
      request["Accept-Language"] = "fr,en-US;q=0.9,en;q=0.8"
      
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      log "request  status : #{response.code}"

      payload = JSON.parse(response.body)

      if interpolated['debug'] == 'true'
        log "payload : #{payload}"
      end

      if interpolated['changes_only'] == 'true'
        if payload.to_s != memory['last_status']
          if "#{memory['last_status']}" == '' or ( payload.to_s != memory['last_status'] and interpolated['without_timestamp_diff'] == 'false')
              create_event payload: payload
          else
            last_status = memory['last_status'].gsub("=>", ": ").gsub(": nil", ": null")
            last_status = JSON.parse(last_status)
            if interpolated['debug'] == 'true'
              log "last_status : #{last_status}"
              log "#{payload['data'][0]['value']} = #{last_status['data'][0]['value']}"
            end
            if interpolated['without_timestamp_diff'] == 'true' and payload['data'][0]['value'] != last_status['data'][0]['value']
              create_event payload: payload
               if interpolated['debug'] == 'true'
                 log "#{payload['data'][0]['value']} = #{last_status['data'][0]['value']}"
               end
            end
          end
          memory['last_status'] = payload.to_s
        end
      else
        create_event payload: payload
        if payload.to_s != memory['last_status']
          memory['last_status'] = payload.to_s
        end
      end
    end
  end
end
