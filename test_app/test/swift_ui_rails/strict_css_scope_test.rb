# frozen_string_literal: true

require "test_helper"

class StrictCssScopeTest < ActiveSupport::TestCase
  StrictCSS = SwiftUIRails::Security::StrictCSS

  setup do
    @previous_global = SwiftUIRails.configuration.strict_css
    Thread.current[StrictCSS::OVERRIDE_KEY] = nil
  end

  teardown do
    Thread.current[StrictCSS::OVERRIDE_KEY] = nil
    SwiftUIRails.configuration.strict_css = @previous_global
  end

  test "nested scopes restore the previous value after normal and exceptional exits" do
    SwiftUIRails.configuration.strict_css = false
    refute StrictCSS.enabled?

    StrictCSS.with(enabled: true) do
      assert StrictCSS.enabled?

      StrictCSS.with(enabled: false) { refute StrictCSS.enabled? }
      assert StrictCSS.enabled?

      assert_raises(RuntimeError) do
        StrictCSS.with(enabled: false) { raise "stop" }
      end
      assert StrictCSS.enabled?
    end

    refute StrictCSS.enabled?
  end

  test "fiber-local scopes do not leak into another render fiber" do
    SwiftUIRails.configuration.strict_css = false

    strict_fiber = Fiber.new do
      StrictCSS.with(enabled: true) do
        first = StrictCSS.enabled?
        Fiber.yield first
        [ first, StrictCSS.enabled? ]
      end
    end
    default_fiber = Fiber.new { StrictCSS.enabled? }

    assert strict_fiber.resume
    refute default_fiber.resume
    assert_equal [ true, true ], strict_fiber.resume
    refute StrictCSS.enabled?
  end

  test "concurrent threads can select opposite strictness without interference" do
    SwiftUIRails.configuration.strict_css = false
    ready = Queue.new
    release = Queue.new
    observed = Queue.new

    threads = [ true, false ].map do |enabled|
      Thread.new do
        StrictCSS.with(enabled: enabled) do
          ready << true
          release.pop
          observed << [ enabled, StrictCSS.enabled? ]
        end
      end
    end

    2.times { ready.pop }
    2.times { release << true }
    results = 2.times.map { observed.pop }.sort_by { |enabled, _value| enabled ? 1 : 0 }
    threads.each(&:join)

    assert_equal [ [ false, false ], [ true, true ] ], results
    refute StrictCSS.enabled?
  end

  test "invalid scope values fail without disturbing an outer override" do
    SwiftUIRails.configuration.strict_css = false

    StrictCSS.with(enabled: true) do
      assert_raises(ArgumentError) { StrictCSS.with(enabled: nil) { flunk } }
      assert StrictCSS.enabled?
    end

    refute StrictCSS.enabled?
  end
end
