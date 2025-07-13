# frozen_string_literal: true

require 'spec_helper'
require 'swift_ui_rails/security/rate_limiter'

RSpec.describe SwiftUIRails::Security::RateLimiter do
  let(:limiter) { described_class.instance }
  let(:key) { 'test_action' }
  let(:threshold) { 5 }
  let(:window) { 60 }

  before do
    # Clear any existing state
    limiter.reset(key)
    # Configure rate limiting
    allow(SwiftUIRails.configuration).to receive(:rate_limit_actions).and_return(true)
    allow(SwiftUIRails.configuration).to receive(:rate_limit_threshold).and_return(threshold)
    allow(SwiftUIRails.configuration).to receive(:rate_limit_window).and_return(window)
  end

  describe '#check' do
    context 'when rate limiting is disabled' do
      before do
        allow(SwiftUIRails.configuration).to receive(:rate_limit_actions).and_return(false)
      end

      it 'always returns true' do
        10.times do
          expect(limiter.check(key)).to be true
        end
      end
    end

    context 'when rate limiting is enabled' do
      it 'allows requests within threshold' do
        threshold.times do
          expect(limiter.check(key)).to be true
        end
      end

      it 'blocks requests exceeding threshold' do
        threshold.times { limiter.check(key) }
        expect(limiter.check(key)).to be false
      end

      it 'allows requests after window expires' do
        threshold.times { limiter.check(key) }
        expect(limiter.check(key)).to be false
        
        # Simulate time passing
        allow(Time).to receive(:now).and_return(Time.now + window + 1)
        
        expect(limiter.check(key)).to be true
      end

      it 'tracks different keys separately' do
        key1 = 'action1'
        key2 = 'action2'
        
        threshold.times { limiter.check(key1) }
        expect(limiter.check(key1)).to be false
        expect(limiter.check(key2)).to be true
      end

      it 'logs rate limit violations' do
        allow(Rails.logger).to receive(:warn)
        
        threshold.times { limiter.check(key) }
        limiter.check(key)
        
        expect(Rails.logger).to have_received(:warn).with(/Rate limit exceeded for key: #{key}/)
      end
    end

    context 'with custom threshold and window' do
      let(:custom_threshold) { 3 }
      let(:custom_window) { 30 }

      it 'respects custom threshold' do
        custom_threshold.times do
          expect(limiter.check(key, threshold: custom_threshold)).to be true
        end
        expect(limiter.check(key, threshold: custom_threshold)).to be false
      end

      it 'respects custom window' do
        custom_threshold.times { limiter.check(key, threshold: custom_threshold, window: custom_window) }
        expect(limiter.check(key, threshold: custom_threshold, window: custom_window)).to be false
        
        # Simulate time passing less than custom window
        allow(Time).to receive(:now).and_return(Time.now + custom_window - 1)
        expect(limiter.check(key, threshold: custom_threshold, window: custom_window)).to be false
        
        # Simulate time passing more than custom window
        allow(Time).to receive(:now).and_return(Time.now + custom_window + 1)
        expect(limiter.check(key, threshold: custom_threshold, window: custom_window)).to be true
      end
    end
  end

  describe '#reset' do
    it 'clears rate limit for a key' do
      threshold.times { limiter.check(key) }
      expect(limiter.check(key)).to be false
      
      limiter.reset(key)
      expect(limiter.check(key)).to be true
    end

    it 'only resets specified key' do
      key1 = 'action1'
      key2 = 'action2'
      
      threshold.times { limiter.check(key1) }
      threshold.times { limiter.check(key2) }
      
      limiter.reset(key1)
      
      expect(limiter.check(key1)).to be true
      expect(limiter.check(key2)).to be false
    end
  end

  describe '#cleanup' do
    it 'removes expired entries' do
      old_key = 'old_action'
      new_key = 'new_action'
      
      # Add old entry
      limiter.check(old_key)
      
      # Simulate time passing beyond window
      allow(Time).to receive(:now).and_return(Time.now + window + 1)
      
      # Add new entry
      limiter.check(new_key)
      
      # Cleanup should remove old entry but keep new one
      cleaned = limiter.send(:cleanup)
      expect(cleaned).to eq(1)
      
      # Old key should start fresh, new key should still be limited
      expect(limiter.instance_variable_get(:@requests)[old_key]).to be_nil
      expect(limiter.instance_variable_get(:@requests)[new_key]).not_to be_nil
    end
  end

  describe 'thread safety' do
    it 'handles concurrent access safely' do
      threads = []
      results = []
      mutex = Mutex.new
      
      10.threads do
        threads << Thread.new do
          5.times do
            result = limiter.check("concurrent_#{Thread.current.object_id}")
            mutex.synchronize { results << result }
          end
        end
      end
      
      threads.each(&:join)
      
      # All requests should succeed since each thread has its own key
      expect(results).to all(be true)
    end
  end

  describe 'memory management' do
    it 'automatically cleans up old entries' do
      # Create many entries
      100.times { |i| limiter.check("key_#{i}") }
      
      # Simulate time passing
      allow(Time).to receive(:now).and_return(Time.now + window + 1)
      
      # Trigger cleanup on next check
      limiter.check('trigger_cleanup')
      
      # Old entries should be cleaned up
      requests = limiter.instance_variable_get(:@requests)
      expect(requests.size).to be <= 2 # Only recent entries remain
    end
  end

  describe 'error handling' do
    it 'handles nil keys gracefully' do
      expect(limiter.check(nil)).to be true
    end

    it 'handles empty keys gracefully' do
      expect(limiter.check('')).to be true
    end

    it 'handles non-string keys' do
      expect(limiter.check(123)).to be true
      expect(limiter.check(:symbol)).to be true
    end
  end
end