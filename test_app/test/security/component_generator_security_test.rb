require "test_helper"
require "generators/swift_ui_rails/component/component_generator"

class ComponentGeneratorSecurityTest < Rails::Generators::TestCase
  tests SwiftUIRails::Generators::ComponentGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination
  
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
      assert_raises Thor::Error do
        run_generator [name]
      end
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
      assert_raises Thor::Error do
        run_generator ["SafeComponent", prop]
      end
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
      "def",              # reserved word
    ]
    
    invalid_names.each do |name|
      assert_raises Thor::Error do
        run_generator [name]
      end
    end
  end
  
  test "rejects Ruby reserved words as prop names" do
    reserved_words = %w[
      alias and begin break case class def defined do else elsif end 
      ensure false for if in module next nil not or redo rescue retry 
      return self super then true undef unless until when while yield
    ]
    
    reserved_words.each do |word|
      assert_raises Thor::Error do
        run_generator ["ValidComponent", "#{word}:String"]
      end
    end
  end
  
  test "sanitizes dangerous type values" do
    # Create generator instance
    generator = SwiftUIRails::Generators::ComponentGenerator.new(["TestComponent", "name:String;system('ls')"])
    
    # The dangerous type should be sanitized to String
    parsed = generator.send(:parsed_props)
    assert_equal "String", parsed.first[:type]
  end
  
  test "allows valid component names and props" do
    # These should work without errors
    assert_nothing_raised do
      run_generator ["UserProfile", "name:String", "age:Integer", "active:Boolean"]
    end
    
    assert_file "app/components/user_profile_component.rb" do |content|
      assert_match(/class UserProfileComponent < ApplicationComponent/, content)
      assert_match(/prop :name, type: String/, content)
      assert_match(/prop :age, type: Integer/, content)
      assert_match(/prop :active, type: Boolean/, content)
    end
  end
  
  test "sanitizes file names" do
    generator = SwiftUIRails::Generators::ComponentGenerator.new(["My Component!!!"])
    
    # Despite invalid input, file name should be safe
    assert_equal "my_component", generator.send(:file_name)
  end
  
  test "sanitizes class names" do
    generator = SwiftUIRails::Generators::ComponentGenerator.new(["My-Component!!!"])
    
    # Despite invalid input, class name should be safe
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
      assert_raises Thor::Error do
        run_generator [name]
      end
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
      "Component\n\r",     # Newlines
    ]
    
    unicode_names.each do |name|
      # Should either raise error or sanitize
      begin
        generator = SwiftUIRails::Generators::ComponentGenerator.new([name])
        # If it doesn't raise, check that it's sanitized
        clean_name = generator.send(:class_name)
        assert_match(/\A[A-Za-z0-9]+\z/, clean_name)
      rescue Thor::Error
        # Expected for invalid names
        assert true
      end
    end
  end
end
# Copyright 2025
