require "capybara/rails"
require "capybara/poltergeist"
require 'atomic'

class IntransientCapybaraTest < ActionDispatch::IntegrationTest
  extend Minitest::OptionalRetry

  include IntransientCapybaraHelper
  include Capybara::DSL

  cattr_accessor :blacklisted_urls
  cattr_writer :default_window_size
  cattr_writer :cache_warmup_path

  @@warm_asset_cache = Atomic.new(false)
  @@warming_asset_cache = Atomic.new(false)

  Capybara.default_max_wait_time = 10
  Capybara.current_driver = :poltergeist
  Capybara.javascript_driver = :poltergeist

  def setup
    super

    @setup_called = true

    if ENV.fetch('TRACE_TEST_FRAMEWORK', false) == 'true'
      puts 'I am in capybara setup method'
    end

    page.driver.browser.url_blacklist = self.class.blacklisted_urls

    resize_window_by default_window_size

    warm_asset_cache

    allow_rack_requests!
  end

  def teardown
    if ENV.fetch('TRACE_TEST_FRAMEWORK', false) == 'true'
      puts 'I am in capybara teardown method'
    end

    @teardown_called = true

    # Wait on outstanding requests (but tests should not do stuff at the end, why bother clicking stuff you don't assert on?)
    # If you don't do this, the next time will fail because the server is busy
    wait_for_response!
    teardown_wait_for_requests_complete!

    report_traffic
    page.driver.clear_network_traffic

    page.driver.clear_cookies
    Capybara.reset_sessions!

    super
  end

  protected

  def after_teardown
    super

    unless @setup_called
      raise 'Setup was not called in the parent!  You MUST call super in your overrides!'
    end

    unless @teardown_called
      raise 'Teardown was not called in the parent!  You MUST call super in your overrides!'
    end
  end

  def default_window_size
    @@default_window_size || [1024, 768]
  end

  def cache_warmup_path
    @@cache_warmup_path || '/'
  end

  def warm_asset_cache
    return if warm_asset_cache?

    if warming_asset_cache?
      wait_for('assets to be warmed up', max_wait_time: 60, polling_interval: 3) do
        warm_asset_cache?
      end
    end

    @@warming_asset_cache.value = true
    puts 'WARMING UP ASSET CACHE...'

    begin
      allow_rack_requests!
      visit cache_warmup_path
      sleep 15
      wait_for_response!
      teardown_wait_for_requests_complete!

      @@warm_asset_cache.value = true
    rescue StandardError => e
      puts "Could not warm asset cache - #{e.class.to_s} - #{e.message}"
      return
    ensure
      @@warming_asset_cache.value = false
    end

    puts 'ASSETS HOT N READY!'
  end

  def warming_asset_cache?
    @@warming_asset_cache.value
  end

  def warm_asset_cache?
    ENV.fetch('TEST_SKIP_WARMING_ASSET_CACHE', false) == 'true' || @@warm_asset_cache.value
  end

end
