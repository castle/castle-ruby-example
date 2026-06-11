# frozen_string_literal: true

# Captures the Castle API interactions made during a request (the endpoint
# called, the payload we sent and the response we got back) so the rendered page
# can show the verdict, risk score and signals. This mirrors the transparency of
# the Castle demo apps in the other languages (Node, Python, PHP).
#
# Results captured in the current request are exposed to the view through the
# `castle_results` helper. For flows that redirect (e.g. a successful login),
# call `persist_castle_results` right before redirecting so the next page can
# still render them via the flash.
module CastleReporting
  extend ActiveSupport::Concern

  # Hard cap on the whole flashed payload so a large `/risk` response can never
  # overflow the (4 KB) cookie-backed session on a redirecting flow. When the
  # compacted results still exceed this, the response bodies are dropped.
  MAX_FLASHED_TOTAL_BYTES = 2_500

  # Request tokens are long; truncate them when persisting to the flash.
  MAX_FLASHED_TOKEN_CHARS = 24

  included do
    helper_method :castle_results
  end

  private

  # Records a single Castle call for display. `response` is the Hash returned by
  # the SDK (risk/filter/log), or nil when the call raised.
  def record_castle_result(endpoint:, payload:, response: nil, error: nil)
    recorded_castle_results << {
      'endpoint' => endpoint.to_s,
      'payload' => stringify_castle(payload),
      'response' => stringify_castle(response),
      'error' => error&.to_s
    }
  end

  # The results to render: those captured in this request, otherwise any carried
  # over a redirect via the flash.
  def castle_results
    if recorded_castle_results.present?
      recorded_castle_results
    else
      flash[:castle_results] || []
    end
  end

  # Persists the captured results across a redirect. The full response can be
  # large, and the cookie-backed session is capped at ~4 KB, so the persisted
  # copy keeps only the verdict, risk score and signal names. The flash is swept
  # once the next request has rendered them.
  def persist_castle_results
    return if recorded_castle_results.blank?

    compacted = recorded_castle_results.map { |entry| compact_for_flash(entry) }
    compacted = compacted.map { |entry| entry.except('response') } if compacted.to_json.bytesize > MAX_FLASHED_TOTAL_BYTES

    flash[:castle_results] = compacted
  end

  # Extracts the policy action ('allow', 'challenge' or 'deny') from a Castle
  # response, tolerating both symbol-keyed (fresh) and string-keyed (flash)
  # hashes.
  def castle_action(response)
    return unless response.is_a?(Hash)

    response.dig(:policy, :action) || response.dig('policy', 'action')
  end

  def recorded_castle_results
    @recorded_castle_results ||= []
  end

  def stringify_castle(value)
    value.is_a?(Hash) ? value.deep_stringify_keys : value
  end

  # Shrinks an entry to the essentials that fit in the cookie-backed session:
  # the verdict, the risk score and the signal names (not their bodies), plus a
  # truncated request token in the echoed payload.
  def compact_for_flash(entry)
    entry.merge(
      'payload' => compact_payload(entry['payload']),
      'response' => compact_response(entry['response'])
    )
  end

  def compact_payload(payload)
    return payload unless payload.is_a?(Hash)
    return payload unless payload['request_token'].is_a?(String)
    return payload if payload['request_token'].length <= MAX_FLASHED_TOKEN_CHARS

    payload.merge('request_token' => "#{payload['request_token'][0, MAX_FLASHED_TOKEN_CHARS]}…")
  end

  def compact_response(response)
    return response unless response.is_a?(Hash)

    compact = response.slice('policy', 'risk')
    signals = response['signals']
    compact['signals'] = signals.keys if signals.is_a?(Hash)
    compact
  end
end
