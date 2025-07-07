# Copyright 2025
require "test_helper"
require "generators/swift_ui_rails/stories/stories_generator"

class StoriesGeneratorSecurityTest < Rails::Generators::TestCase
  tests SwiftUIRails::Generators::StoriesGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  test "prevents code injection through component name" do
    dangerous_names = [
      "User; system('rm -rf /')",
      "Evil`touch /tmp/hacked`",
      "Malicious\"; exec('ls'); \"",
      "Bad'; eval('File.read(\"/etc/passwd\")')",
      "Inject$(whoami)",
      "Hack|ls",
      "Break&& echo pwned"
    ]

    dangerous_names.each do |name|
      prepare_destination
      run_generator [ name ]

      # Verify no files created
      safe_name = name.gsub(/[^a-z0-9_]/i, "_").underscore
      assert_no_file "test/components/stories/#{safe_name}_component_stories.rb"
      assert_no_file "test/components/stories/#{safe_name}_component_preview.html.erb"
    end
  end

  test "prevents injection through story names" do
    dangerous_stories = [
      "evil;system('ls')",
      "bad`touch /tmp/hacked`",
      "hack$(whoami)",
      "inject|ls",
      "break&&echo",
      "story;eval('1+1')",
      "exec('id')",
      "system"
    ]

    dangerous_stories.each do |story|
      prepare_destination
      run_generator [ "SafeComponent", story ]

      # Verify no files created
      assert_no_file "test/components/stories/safe_component_stories.rb"
    end
  end

  test "rejects invalid story names" do
    invalid_stories = [
      "123story",          # starts with number
      "-story",            # starts with dash
      "story-name",        # contains dash
      "story name",        # contains space
      "STORY",             # uppercase
      "Story",             # capitalized
      ""                  # empty
    ]

    invalid_stories.each do |story|
      prepare_destination
      run_generator [ "ValidComponent", story ]

      # Verify no files created
      assert_no_file "test/components/stories/valid_component_stories.rb"
    end
  end

  test "allows valid component and story names" do
    assert_nothing_raised do
      run_generator [ "UserProfile", "default", "with_avatar", "loading_state" ]
    end

    assert_file "test/components/stories/user_profile_component_stories.rb" do |content|
      assert_match(/class UserProfileComponentStories/, content)
      # Check for story definitions using the new story DSL
      assert_match(/story :default/, content)
      assert_match(/story :with_avatar/, content)
      assert_match(/story :loading_state/, content)
    end
  end

  test "sanitizes component class names" do
    generator = SwiftUIRails::Generators::StoriesGenerator.new([ "My-Component!!!" ])

    # Despite invalid input, class name should be safe
    assert_equal "MyComponent", generator.send(:class_name)
    assert_equal "MyComponentComponent", generator.send(:component_class_name)
  end

  test "filters out invalid story names" do
    generator = SwiftUIRails::Generators::StoriesGenerator.new([
      "ValidComponent",
      "valid_story",
      "INVALID",
      "also-invalid",
      "123bad",
      "another_valid"
    ])

    # Should only keep valid story names
    stories = generator.send(:story_names)
    assert_equal [ "valid_story", "another_valid" ], stories
  end

  test "safe constantize in component_class" do
    # Create a test component
    Object.const_set("TestSafeComponent", Class.new(ViewComponent::Base))

    generator = SwiftUIRails::Generators::StoriesGenerator.new([ "TestSafe" ])
    component = generator.send(:component_class)

    assert_equal TestSafeComponent, component
  ensure
    Object.send(:remove_const, "TestSafeComponent") if Object.const_defined?("TestSafeComponent")
  end

  test "rejects non-component classes" do
    # Create a non-component class
    Object.const_set("NotAComponent", Class.new)

    generator = SwiftUIRails::Generators::StoriesGenerator.new([ "NotA" ])
    component = generator.send(:component_class)

    # Should return nil for non-component classes
    assert_nil component
  ensure
    Object.send(:remove_const, "NotAComponent") if Object.const_defined?("NotAComponent")
  end

  test "handles missing component gracefully" do
    generator = SwiftUIRails::Generators::StoriesGenerator.new([ "NonExistent" ])
    component = generator.send(:component_class)

    # Should return nil for missing components
    assert_nil component
  end

  test "default story names when none provided" do
    generator = SwiftUIRails::Generators::StoriesGenerator.new([ "MyComponent" ])

    # Should provide default stories
    assert_equal [ "default", "playground" ], generator.send(:story_names)
  end

  test "prevents directory traversal" do
    dangerous_names = [
      "../../../etc/passwd",
      "..\\..\\..\\windows",
      "../../config/secrets"
    ]

    dangerous_names.each do |name|
      prepare_destination
      run_generator [ name ]

      # Verify no files created
      assert_no_file "test/components/stories/passwd_stories.rb"
      assert_no_file "../../../etc/passwd"
    end
  end

  test "handles special characters in file names" do
    # Create a generator with proper initialization
    prepare_destination

    # Create the generator and set the name
    generator = SwiftUIRails::Generators::StoriesGenerator.new([ "My_Component" ])
    generator.instance_variable_set(:@name, "My_Component")

    # Test that file_name method properly sanitizes
    assert_equal "my_component", generator.send(:file_name)
  end
end
# Copyright 2025
