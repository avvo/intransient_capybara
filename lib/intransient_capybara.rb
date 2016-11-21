require 'intransient_capybara/version'
require 'intransient_capybara/patches'
require 'intransient_capybara/minitest_retry'
require 'intransient_capybara/intransient_capybara_helper'

module IntransientCapybara
  autoload :IntransientCapybaraTest, 'intransient_capybara/intransient_capybara_test'
  autoload :RackRequestBlocker, 'intransient_capybara/rack_request_blocker'
end
