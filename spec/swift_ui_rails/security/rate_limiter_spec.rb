# frozen_string_literal: true

require 'spec_helper'
require 'swift_ui_rails/security/rate_limiter'

RSpec.describe SwiftUIRails::Security::RateLimiter do
  let(:cache_store) { ActiveSupport::Cache::MemoryStore.new }
  let(:limiter) { described_class.new(store: cache_store, threshold: threshold, window: window) }
  let(:key) { 'test_action' }
  let(:threshold) { 5 }
  let(:window) { 60 }

  before do
    # Clear any existing state
    limiter.reset!(key)
    # Configure rate limiting
    allow(SwiftUIRails.configuration).to receive(:rate_limit_actions).and_return(true)
    allow(SwiftUIRails.configuration).to receive(:rate_limit_threshold).and_return(threshold)
    allow(SwiftUIRails.configuration).to receive(:rate_limit_window).and_return(window)
  end

  describe '#allow? and #record!' do
    context 'when rate limiting is disabled' do
      before do
        allow(SwiftUIRails.configuration).to receive(:rate_limit_actions).and_return(false)
      end

      it 'always returns true for allow?' do
        10.times do
          expect(limiter.allow?(key)).to be true
        end
      end

      it 'always returns true for record!' do
        10.times do
          expect(limiter.record!(key)).to be true
        end
      end
    end

    context 'when rate limiting is enabled' do
      it 'allows requests within threshold' do
        threshold.times do
          expect(limiter.allow?(key)).to be true
          limiter.record!(key)
        end
      end

      it 'blocks requests exceeding threshold' do
        threshold.times { limiter.record!(key) }
        expect(limiter.allow?(key)).to be false
      end

      it 'raises exception when recording exceeds threshold' do
        threshold.times { limiter.record!(key) }
        expect { limiter.record!(key) }.to raise_error(SwiftUIRails::Security::RateLimiter::RateLimitExceeded)
      end

      it 'tracks different keys separately' do
        key1 = 'action1'
        key2 = 'action2'
        
        threshold.times { limiter.record!(key1) }
        expect(limiter.allow?(key1)).to be false
        expect(limiter.allow?(key2)).to be true
      end

      it 'logs rate limit violations' do
        allow(Rails.logger).to receive(:warn)
        
        threshold.times { limiter.record!(key) }
        limiter.allow?(key)
        
        expect(Rails.logger).to have_received(:warn).with(/Rate limit exceeded for #{key}/)
      end
    end

    context 'with custom limiter settings' do
      let(:custom_threshold) { 3 }
      let(:custom_window) { 30 }
      let(:custom_limiter) { described_class.new(store: cache_store, threshold: custom_threshold, window: custom_window) }

      it 'respects custom threshold' do
        custom_threshold.times do
          expect(custom_limiter.allow?(key)).to be true
          custom_limiter.record!(key)
        end
        expect(custom_limiter.allow?(key)).to be false
      end

      it 'provides current count' do
        2.times { custom_limiter.record!(key) }
        expect(custom_limiter.current_count(key)).to eq(2)
      end

      it 'provides remaining count' do
        2.times { custom_limiter.record!(key) }
        expect(custom_limiter.remaining(key)).to eq(1)
      end
    end
  end

  describe '#reset!' do
    it 'clears rate limit for a key' do
      threshold.times { limiter.record!(key) }
      expect(limiter.allow?(key)).to be false
      
      limiter.reset!(key)
      expect(limiter.allow?(key)).to be true
    end

    it 'only resets specified key' do
      key1 = 'action1'
      key2 = 'action2'
      
      threshold.times { limiter.record!(key1) }
      threshold.times { limiter.record!(key2) }
      
      limiter.reset!(key1)
      
      expect(limiter.allow?(key1)).to be true
      expect(limiter.allow?(key2)).to be false
    end
  end

  describe 'thread safety' do
    it 'handles concurrent access safely' do
      threads = []
      results = []
      mutex = Mutex.new
      
      10.times do
        threads << Thread.new do
          5.times do
            result = limiter.allow?("concurrent_#{Thread.current.object_id}")
            mutex.synchronize { results << result }
          end
        end
      end
      
      threads.each(&:join)
      
      # All requests should succeed since each thread has its own key
      expect(results).to all(be true)
    end
  end

  describe 'error handling' do
    it 'handles nil keys gracefully' do
      expect(limiter.allow?(nil)).to be true
    end

    it 'handles empty keys gracefully' do
      expect(limiter.allow?('')).to be true
    end

    it 'handles non-string keys' do
      expect(limiter.allow?(123)).to be true
      expect(limiter.allow?(:symbol)).to be true
    end

    it 'fails gracefully when cache store fails' do
      allow(cache_store).to receive(:read).and_raise(StandardError.new("Cache error"))
      allow(Rails.logger).to receive(:error)
      
      # Should not raise error, just log and allow
      expect(limiter.allow?(key)).to be true
    end
  end
end