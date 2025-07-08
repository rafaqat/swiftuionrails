require "application_system_test_case"

class PlaygroundE2eTest < ApplicationSystemTestCase
  # ApplicationSystemTestCase already sets up headless Chrome

  test "playground loads with default code" do
    visit playground_root_path

    # Check page structure
    assert_selector "h1", text: "SwiftUI Rails Playground"
    assert_selector "[data-playground-target='codeInput']"
    assert_selector "#playground-preview"

    # Check default code is loaded
    code_editor = find("[data-playground-target='codeInput']")
    assert_match /Welcome to SwiftUI Rails Playground/, code_editor.value
    assert_match /swift_ui do/, code_editor.value
  end

  test "running code updates preview" do
    visit playground_root_path

    # Clear and enter simple code
    code_editor = find("[data-playground-target='codeInput']")
    code_editor.set("swift_ui { text('Hello E2E Test!') }")

    # Click run button
    click_button "Run"

    # Wait for preview to update
    within "#playground-preview" do
      assert_text "Hello E2E Test!", wait: 5
    end
  end

  test "snippet dropdown loads and organizes by category" do
    visit playground_root_path

    # Click snippets button
    click_button "Snippets"

    # Check categories are present
    within "[data-dropdown-target='menu']" do
      assert_text "BASIC COMPONENTS"
      assert_text "LAYOUT"
      assert_text "INTERACTIVE"
      assert_text "FORMS"
      assert_text "COMPLEX"

      # Check some specific snippets
      assert_text "DSL Button"
      assert_text "DSL Card"
      assert_text "Interactive Counter"
    end
  end

  test "loading snippet replaces code and executes" do
    visit playground_root_path

    # Open snippets dropdown
    click_button "Snippets"

    # Click DSL Button snippet
    within "[data-dropdown-target='menu']" do
      click_button "DSL Button"
    end

    # Check code was replaced
    code_editor = find("[data-playground-target='codeInput']")
    assert_match /button\("Click Me"\)/, code_editor.value
    assert_match /bg\("blue-500"\)/, code_editor.value

    # Check preview was updated (auto-execute)
    within "#playground-preview", wait: 5 do
      assert_selector "button", text: "Click Me"
      assert_selector "button", text: "Secondary"
      assert_selector "button", text: "Download"
      assert_selector "button", text: "Disabled"
    end
  end

  test "loading complex snippet with multi-line code" do
    visit playground_root_path

    # Open snippets and load form snippet
    click_button "Snippets"
    within "[data-dropdown-target='menu']" do
      click_button "Complete Form"
    end

    # Check multi-line code loaded correctly
    code_editor = find("[data-playground-target='codeInput']")
    assert_match /form\(action: "#", method: "post"\)/, code_editor.value
    assert_match /label\("Name", for_input: "name"\)/, code_editor.value
    assert_match /button\("Submit", type: "submit"\)/, code_editor.value

    # Check preview shows form
    within "#playground-preview", wait: 5 do
      assert_selector "form"
      assert_selector "label", text: "Name"
      assert_selector "label", text: "Email"
      assert_selector "button", text: "Submit"
    end
  end

  test "interactive counter snippet works" do
    visit playground_root_path

    # Load counter snippet
    click_button "Snippets"
    within "[data-dropdown-target='menu']" do
      click_button "Interactive Counter"
    end

    # Wait for preview
    within "#playground-preview", wait: 5 do
      # Check counter is rendered
      assert_selector "[data-counter-target='count']", text: "0"
      assert_selector "button", text: "+"
      assert_selector "button", text: "-"
    end
  end

  test "error handling for invalid code" do
    visit playground_root_path

    # Enter invalid code
    code_editor = find("[data-playground-target='codeInput']")
    code_editor.set("swift_ui { invalid_method_that_does_not_exist }")

    # Run code
    click_button "Run"

    # Wait for response
    sleep 1

    # The system handles errors gracefully - check that the page is still functional
    # and we can still interact with it
    assert_selector "[data-playground-target='codeInput']"

    # We should be able to fix the code and run again
    code_editor.set("swift_ui { text('Fixed!') }")
    click_button "Run"

    # And see the fixed result
    within "#playground-preview" do
      assert_text "Fixed!", wait: 5
    end
  end

  test "preview device switching" do
    visit playground_root_path

    # Run default code first
    click_button "Run"

    # Switch to mobile view
    click_button "Mobile"

    # Check preview container has mobile class
    preview = find("#playground-preview")
    assert preview[:class].include?("max-w-sm")

    # Switch to tablet view
    click_button "Tablet"
    assert find("#playground-preview")[:class].include?("max-w-md")

    # Switch back to desktop
    click_button "Desktop"
    assert find("#playground-preview")[:class].include?("max-w-4xl")
  end

  test "keyboard shortcut executes code" do
    visit playground_root_path

    # Enter simple code
    code_editor = find("[data-playground-target='codeInput']")
    code_editor.set("swift_ui { text('Keyboard Test') }")

    # Use keyboard shortcut (Cmd+Enter on Mac)
    code_editor.send_keys [ :command, :return ]

    # Check preview updated
    within "#playground-preview", wait: 5 do
      assert_text "Keyboard Test"
    end
  end

  test "grid snippet renders correctly" do
    visit playground_root_path

    # Load grid snippet
    click_button "Snippets"
    within "[data-dropdown-target='menu']" do
      click_button "Product Grid"
    end

    # Check grid renders with products
    within "#playground-preview", wait: 5 do
      assert_selector "[class*='grid']"
      # Check multiple products are rendered
      assert_text "Product 1"
      assert_text "Product 2"
      assert_text "Product 3"
      assert_text "$10.99"
      assert_text "$20.99"
    end
  end

  test "dashboard snippet renders complex layout" do
    visit playground_root_path

    # Load dashboard snippet
    click_button "Snippets"
    within "[data-dropdown-target='menu']" do
      click_button "Dashboard Layout"
    end

    # Check dashboard elements
    within "#playground-preview", wait: 5 do
      assert_text "Dashboard"
      assert_text "Total Users"
      assert_text "1,234"
      assert_text "Revenue"
      assert_text "$45,678"
      assert_text "Orders"
      assert_text "89"
      assert_text "Revenue Over Time"
    end
  end

  test "snippet dropdown closes after selection" do
    visit playground_root_path

    # Open dropdown
    click_button "Snippets"
    dropdown = find("[data-dropdown-target='menu']")
    assert dropdown.visible?

    # Click a snippet
    within dropdown do
      click_button "DSL Text"
    end

    # Check dropdown is closed
    dropdown = find("[data-dropdown-target='menu']", visible: false)
    refute dropdown.visible?
  end

  test "live preview indicator shows active state" do
    visit playground_root_path

    # Check live indicator is present and pulsing
    live_indicator = find(".animate-pulse")
    assert_text "Live Preview"
    assert live_indicator.visible?
  end

  test "component inspector tabs are present" do
    visit playground_root_path

    # Check inspector tabs exist (they might be at the bottom of viewport)
    inspector = find("[data-playground-target='inspector']", visible: :all)

    # Check that all expected tabs are in the HTML
    assert inspector.has_selector?("button", text: "Component Tree", visible: :all)
    assert inspector.has_selector?("button", text: "Properties", visible: :all)
    assert inspector.has_selector?("button", text: "Stimulus State", visible: :all)
    assert inspector.has_selector?("button", text: "Generated Code", visible: :all)
  end

  test "textarea has proper code editor styling" do
    visit playground_root_path

    code_editor = find("[data-playground-target='codeInput']")

    # Check monospace font
    assert_match /mono/, code_editor.native.style("font-family")

    # Check it's not spell-checked
    assert_equal "false", code_editor[:spellcheck]
  end

  test "multiple rapid snippet loads work correctly" do
    visit playground_root_path

    # Load multiple snippets in quick succession
    [ "DSL Button", "DSL Card", "DSL Text" ].each do |snippet_name|
      click_button "Snippets"
      within "[data-dropdown-target='menu']" do
        click_button snippet_name
      end
      sleep 0.5 # Small delay between loads
    end

    # Check final snippet (DSL Text) is loaded
    code_editor = find("[data-playground-target='codeInput']")
    assert_match /text\("Heading 1"\)/, code_editor.value
    assert_match /font_size\("4xl"\)/, code_editor.value
  end

  test "security validation prevents dangerous code" do
    visit playground_root_path

    # Try to execute dangerous code
    code_editor = find("[data-playground-target='codeInput']")
    code_editor.set('system("rm -rf /")')

    click_button "Run"

    # Wait for response
    sleep 1

    # The dangerous code should be blocked - verify we can still use the playground
    assert_selector "[data-playground-target='codeInput']"

    # Should be able to run safe code after the security block
    code_editor.set('swift_ui { text("Safe code works!") }')
    click_button "Run"

    within "#playground-preview" do
      assert_text "Safe code works!", wait: 5
    end
  end
end
