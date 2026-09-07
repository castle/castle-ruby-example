# frozen_string_literal: true

module Vendor
  # Serves the Castle browser SDK from the npm install (node_modules).
  class CastleJsController < ActionController::Base
    DIST = Rails.root.join('node_modules/@castleio/castle-js/dist')
    # 2.x ships castle.browser.js; 3.x ships castle.umd.js. The HTML always requests castle.umd.js.
    ALIASES = {
      'castle.umd.js' => %w[castle.umd.js castle.browser.js],
      'castle.browser.js' => %w[castle.browser.js castle.umd.js]
    }.freeze

    skip_forgery_protection

    def show
      path = resolved_file
      return head :not_found unless path

      send_file path, type: 'application/javascript', disposition: 'inline'
    end

    private

    def resolved_file
      root = DIST.expand_path
      names = ALIASES[params[:filename].to_s] || [params[:filename].to_s]
      names.each do |name|
        candidate = root.join(name).expand_path
        next unless candidate.to_s.start_with?("#{root}#{File::SEPARATOR}")
        return candidate if candidate.file?
      end
      nil
    end
  end
end
