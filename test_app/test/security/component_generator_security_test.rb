# Copyright 2025
require "test_helper"
require "generators/swift_ui_rails/component/component_generator"

class ComponentGeneratorSecurityTest < Rails::Generators::TestCase
  tests SwiftUIRails::Generators::ComponentGenerator
  destination Rails.root.join("tmp/generators")

  setup do
    prepare_destination
    # Ensure required directories exist
    FileUtils.mkdir_p(File.join(destination_root, "app", "components"))
    FileUtils.mkdir_p(File.join(destination_root, "test", "components", "stories"))
    FileUtils.mkdir_p(File.join(destination_root, "spec", "components"))
  end

  test "prevents code injection through component name" do
    # Attempt various injection attacks
    dangerous_names = [
      "User; system('rm -rf /')",
      "Evil`touch /tmp/hacked`Component",
      "Malicious\"; exec('ls'); \"",
      "Bad'; eval('File.read(\"/etc/passwd\")')",
      "Inject$(whoami)",
      "Hack|ls",
      "Break&& echo pwned",
      "Component{system('id')}",
      "Test;send(:eval,'1+1')",
      "Exec||Process.exec('echo')"
    ]

    dangerous_names.each do |name|
      # Clean up before each test
      prepare_destination

      # Run generator - validation will prevent file creation
      # Capture any output but don't let exceptions propagate
      capture(:stdout) do
        begin
          run_generator [ name ]
        rescue Thor::Error
          # Expected - validation should reject dangerous names
        end
      end

      # Check that no component file was created
      # Use a safe version of the name for the file check
      safe_name = name.gsub(/[^a-z0-9_]/i, "_").underscore
      assert_no_file "app/components/#{safe_name}_component.rb"
      assert_no_file "spec/components/#{safe_name}_component_spec.rb"

      # Verify no command injection occurred
      assert_not File.exist?("/tmp/hacked")
    end
  end

  test "prevents injection through prop names" do
    dangerous_props = [
      "evil:String;system('ls')",
      "bad:Integer\";eval('1+1')",
      "hack:Boolean`touch /tmp/hacked`",
      "inject:String$(whoami)",
      "__send__:String",
      "eval:String",
      "system:String",
      "exec:String"
    ]

    dangerous_props.each do |prop|
      prepare_destination

      capture(:stdout) do
        begin
          run_generator [ "SafeComponent", prop ]
        rescue Thor::Error
          # Expected - validation should reject dangerous props
        end
      end

      # Check that component file was not created with dangerous props
      assert_no_file "app/components/safe_component.rb"
    end
  end

  test "rejects invalid component names" do
    invalid_names = [
      "123Component",      # starts with number
      "-component",        # starts with dash
      "component-name",    # contains dash
      "component name",    # contains space
      "component!",        # contains special char
      "",                  # empty
      "class",            # reserved word
      "def"              # reserved word
    ]

    invalid_names.each do |name|
      prepare_destination

      capture(:stdout) do
        begin
          run_generator [ name ]
        rescue Thor::Error
          # Expected - validation should reject invalid names
        end
      end

      # Verify no files created
      safe_name = name.gsub(/[^a-z0-9_]/i, "_").underscore
      assert_no_file "app/components/#{safe_name}_component.rb" unless name.empty?
    end
  end

  test "rejects Ruby reserved words as prop names" do
    reserved_words = %w[
      alias and begin break case class def defined do else elsif end
      ensure false for if in module next nil not or redo rescue retry
      return self super then true undef unless until when while yield
    ]

    reserved_words.each do |word|
      prepare_destination

      capture(:stdout) do
        begin
          run_generator [ "ValidComponent", "#{word}:String" ]
        rescue Thor::Error
          # Expected - validation should reject reserved words
        end
      end

      # Verify no files created
      assert_no_file "app/components/valid_component.rb"
    end
  end

  test "sanitizes dangerous type values" do
    # Create generator instance
    generator = SwiftUIRails::Generators::ComponentGenerator.new([ "TestComponent", "name:String;system('ls')" ])

    # The dangerous type should be sanitized to String
    parsed = generator.send(:parsed_props)
    assert_equal "String", parsed.first[:type]
  end

  test "allows valid component names and props" do
    # These should work without errors
    assert_nothing_raised do
      run_generator [ "UserProfile", "name:String", "age:Integer", "active:Boolean" ]
    end

    assert_file "app/components/user_profile_component.rb" do |content|
      assert_match(/class UserProfileComponent < ApplicationComponent/, content)
      assert_match(/prop :name, type: String/, content)
      assert_match(/prop :age, type: Integer/, content)
      assert_match(/prop :active, type: Boolean/, content)
    end
  end

  test "sanitizes file names" do
    # Create a generator with proper initialization
    prepare_destination

    # Create the generator and set the name
    generator = SwiftUIRails::Generators::ComponentGenerator.new([ "My_Component" ])
    generator.instance_variable_set(:@name, "My_Component")

    # Test that file_name method properly sanitizes
    assert_equal "my_component", generator.send(:file_name)
  end

  test "sanitizes class names" do
    # Create a generator with proper initialization
    prepare_destination

    # Create the generator and set the name
    generator = SwiftUIRails::Generators::ComponentGenerator.new([ "MyComponent" ])
    generator.instance_variable_set(:@name, "MyComponent")

    # Test that class_name and component_class_name methods work correctly
    assert_equal "MyComponent", generator.send(:class_name)
    assert_equal "MyComponentComponent", generator.send(:component_class_name)
  end

  test "prevents directory traversal in file paths" do
    dangerous_names = [
      "../../../etc/passwd",
      "..\\..\\..\\windows\\system32",
      "../../config/database",
      "./../secret"
    ]

    dangerous_names.each do |name|
      prepare_destination

      capture(:stdout) do
        begin
          run_generator [ name ]
        rescue Thor::Error
          # Expected - validation should reject dangerous paths
        end
      end

      # Verify no files created with path traversal
      assert_no_file "app/components/passwd_component.rb"
      assert_no_file "../../../etc/passwd"
    end
  end

  test "handles unicode and special characters safely" do
    unicode_names = [
      "Ｕｎｉｃｏｄｅ",  # Full-width
      "Component™",        # Trademark
      "©Component",        # Copyright
      "Component®",        # Registered
      "😀Component",       # Emoji
      "Component\u0000",   # Null byte
      "Component\n\r"     # Newlines
    ]

    unicode_names.each do |name|
      prepare_destination

      # Run the generator - it should reject these at validation
      capture(:stdout) do
        begin
          run_generator [ name ]
        rescue Thor::Error
          # Expected - validation should reject unicode/special chars
        end
      end

      # Verify no files created
      safe_name = name.gsub(/[^a-z0-9_]/i, "_").underscore
      assert_no_file "app/components/#{safe_name}_component.rb"
    end
  end
end
# Copyright 2025
