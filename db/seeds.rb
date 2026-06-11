# frozen_string_literal: true

# Seeds the demo user that the login page's "valid user + pw" quick-fill signs
# in as. Safe to run repeatedly.
user = DemoAccount.seed!
puts "Seeded demo user: #{user.email}"
