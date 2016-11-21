# Intransient Capybara

This gem provides a set of improvements to the commonly used test technology stack of Minitest, Capybara, Poltergeist, and PhantomJS for rails applications, intended to reduce the occurrence of transient failures.

This gem is inspired by all of these posts:

https://bibwild.wordpress.com/2016/02/18/struggling-towards-reliable-capybara-javascript-testing/
https://semaphoreci.com/community/tutorials/how-to-deal-with-and-eliminate-flaky-tests
http://www.urbanbound.com/make/fix-flaky-feature-tests-by-using-capybaras-apis-properly
http://johnpwood.net/2015/04/23/tips-and-tricks-for-dubugging-and-fixing-slowflaky-capybara-specs/
http://tech.simplybusiness.co.uk/2015/02/25/flaky-tests-and-capybara-best-practices/
https://www.joinhandshake.com/engineering/2016/03/15/tackling-flaky-capybara-tests.html
https://robots.thoughtbot.com/write-reliable-asynchronous-integration-tests-with-capybara
https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2646/diffs
https://github.com/appfolio/minitest-optional_retry

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'intransient_capybara'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install intransient_capybara

## Usage

Inherit from IntransientCapybaraTest in all your integration tests

```ruby
    require 'intransient_capybara/intransient_capybara_test'

    class MyAppsIntegrationTestClass < IntransientCapybaraTest
    
        def setup
            set_up_mocks
            
            # This ought to be called last
            super
        end
        
        def teardown
            # This *really* should be called first because it stops requests before you clear stuff out
            super
            
            clear_out_cache
            clear_out_redis
            clear_out_class_variables
            clear_out_job_queue
            DatabaseCleaner.clean
        end
    
    end
```

Include RackRequestBlocker.  You could do this in an "if test" block in application.rb but I like to include it in config/environments/test.rb.

```ruby
  require File.expand_path('../../../test/rack_request_blocker', __FILE__)
  config.middleware.insert_before('ActionDispatch::Static', 'RackRequestBlocker')
```

Register the driver

```ruby

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app,
        {
          phantomjs_logger: StringIO.new,
          logger: StringIO.new,
          timeout: 60,
          debug: ENV['DEBUG_POLTERGEIST'],
          phantomjs_options:
            [
              '--load-images=no',
              '--ignore-ssl-errors=yes',
              '--resource-timeout=30',
            ],
        }
      )
    end

```

###Debuggability

1. When an element is not found, we output what the current path is and the page's entire HTML, to debug what is going on.  A common case is getting redirected somewhere else, and another is the wrong template is rendering or your partial is not rendering at all.  Sometimes you look at the HTML and your element is there and knowing that will help figure out why the selector isn't working.

2. When environment variable DEBUG_TEST_TRAFFIC is 'true', we output a summary of network traffic from each test.  If you are downloading a lot of stuff or making inordinant amounts of calls it will be insightful to you to know this - it might be reducable, or you may need to preload stuff, etc.  You can also set DEBUG_TEST_TRAFFIC_RAISE_EXTERNAL to 'true' and we will throw an exception if you make a network call to an external service.  This is super common and you should either stub out all of these or add them to the blacklist.  jQuery is a common one if you are loading that JS from a CDN, and you may need to load it from the asset pipeline during tests instead.

3. When environment variable TRACE_TEST_FRAMEWORK is 'true', we output some traces of blocking rack requests and the calling of test setup and teardown.  This can help you make sure your ordering is correct and could help you see if things are happening concurrently or not.

###Correct configuration

1. Capybara.default_max_wait_time is a very important decision.  This gem defaults that to 10 seconds.  More than that and you're probably failing anyways and you're just extending your test run for no reason.  Much less and you get transient.  Time is less important than stability and 10 seconds is a good balance on the stabiltiy side of the world.  You can override this by setting Capybara.default_max_wait_time again in your inherited class.

2. Set phantomjs_options when you set up Poltergeist.  Not loading images and ignoring SSL errors are the common suggestions to improve stability in PhantomJS.

###Correct usage of Capybara/Poltergeist/PhantomJS

1. You need to setup and teardown consistently in your tests, so we will throw an exception if you override one of these and forget to call super (which is SUPER common).

2. When you reach a timeout, a warning is printed.  Sometimes writing a test wrong will always reach the timeout so this helps to improve test performance.  This is similar to capybara-slow_finder_errors but since we are patching this method for another reason as well we also patch this part.  https://github.com/ngauthier/capybara-slow_finder_errors.

3. A lot of stuff gets downloaded on the first page load, so a lot of transient tests are because of the very first page load.  We will load a page for you before we run tests to fix this.  The root path is default, and you can override it with IntransientCapybaraTest.cache_warmup_path = 'my path'.

### Capybara/Poltergeist/PhantomJS improvements

1. Rack request blocker - http://blog.salsify.com/engineering/tearing-capybara-ajax-tests.  TLDR, use middleware to trace server calls so we KNOW when requests are complete before moving on to the next test.  This helps a LOT.  For example, if you clear out mocks in your teardown method, and you call teardown while an AJAX request is still running, you can have problems from missing mocks because of this race condition.

2. Minitest retry.  This is two parts.  First, no matter what you do, sometimes PhantomJS dies on you.  We catch DeadClient and will retry a test once if it gets thrown.  Next, more controversially, even after all the improvements represented here and elsewhere, sometimes we get transient tests.  We do our best, but they're there.  Most of the time we re-run them and move on.  Why waste time re-running them manually?  We will run tests the number of times the environment variable MINITEST_RETRY_COUNT is set to, defaulting to 3 times (so, 2 retries for every test by default).  If it fails at first then succeeds, we will output that it is a transient test and report the success of the test.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/avvo/intransient_capybara.

