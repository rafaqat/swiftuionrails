require "application_system_test_case"

class DslBlockSyntaxTest < ApplicationSystemTestCase
  def setup
    if ENV['CI'] || ENV['HEADLESS']
      Capybara.current_driver = :selenium_chrome_headless
    end
    
    visit "/"
    sleep 2
  end

  test "div.relative with block works" do
    test_code = <<~'RUBY'
      swift_ui do
        div.relative do
          text("Relative content")
        end
      end
    RUBY
    
    page.execute_script("window.monacoEditorInstance.setValue(#{test_code.inspect})")
    sleep 1
    
    within "#preview-container" do
      assert_text "Relative content", wait: 5
    end
  end

  test "div.absolute with block works" do
    test_code = <<~'RUBY'
      swift_ui do
        div.absolute do
          text("Absolute content")
        end
      end
    RUBY
    
    page.execute_script("window.monacoEditorInstance.setValue(#{test_code.inspect})")
    sleep 1
    
    within "#preview-container" do
      assert_text "Absolute content", wait: 5
    end
  end

  test "div.fixed with block works" do
    test_code = <<~'RUBY'
      swift_ui do
        div.fixed do
          text("Fixed content")
        end
      end
    RUBY
    
    page.execute_script("window.monacoEditorInstance.setValue(#{test_code.inspect})")
    sleep 1
    
    within "#preview-container" do
      assert_text "Fixed content", wait: 5
    end
  end

  test "span with block works" do
    test_code = <<~'RUBY'
      swift_ui do
        span do
          text("Span content")
        end
      end
    RUBY
    
    page.execute_script("window.monacoEditorInstance.setValue(#{test_code.inspect})")
    sleep 1
    
    within "#preview-container" do
      assert_text "Span content", wait: 5
    end
  end
end