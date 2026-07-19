require "test_helper"
require "minitest/mock"
require "tmpdir"
require "generators/swift_ui_rails/stories/stories_generator"

class StoriesGeneratorSecurityTest < Rails::Generators::TestCase
  tests SwiftUIRails::Generators::StoriesGenerator
  destination Rails.root.join("tmp/generators/stories_generator_security")
  setup :prepare_isolated_destination
  teardown :remove_isolated_destination
  
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
      assert_raises Thor::Error do
        generator_for(name).validate_component_name!
      end
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
      assert_raises Thor::Error do
        generator_for("SafeComponent", story).validate_story_names!
      end
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
      "",                  # empty
    ]
    
    invalid_stories.each do |story|
      assert_raises Thor::Error do
        generator_for("ValidComponent", story).validate_story_names!
      end
    end
  end

  test "rejects Ruby reserved words as story method names" do
    %w[
      alias and begin break case class def defined do else elsif end ensure
      false for if in module next nil not or redo rescue retry return self
      super then true undef unless until when while yield
    ].each do |story|
      error = assert_raises Thor::Error do
        generator_for("ValidComponent", story).validate_story_names!
      end

      assert_match(/reserved word/, error.message)
    end
  end
  
  test "allows valid component and story names" do
    assert_nothing_raised do
      run_generator ["UserProfile", "default", "with_avatar", "loading_state"]
    end
    
    assert_file "test/components/stories/user_profile_component_stories.rb" do |content|
      assert_match(/class UserProfileComponentStories/, content)
      assert_match(/story :default/, content)
      assert_match(/story :with_avatar/, content)
      assert_match(/story :loading_state/, content)
    end
  end

  test "fails before writing files when the optional Storybook provider is absent" do
    generator = generator_for("UserProfile", "default")
    error = SwiftUIRails.stub(:storybook_available?, false) do
      SwiftUIRails.stub(:load_storybook, false) do
        assert_raises(Thor::Error) { generator.ensure_storybook_available! }
      end
    end

    assert_includes error.message, "view_component/storybook"
    assert_no_file "test/components/stories/user_profile_component_stories.rb"
    assert_no_file "test/components/stories/user_profile_component_preview.html.erb"
  end
  
  test "sanitizes component class names" do
    generator = SwiftUIRails::Generators::StoriesGenerator.new(["My-Component!!!"])
    
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
    assert_equal ["valid_story", "another_valid"], stories
  end
  
  test "safe constantize in component_class" do
    # Create a test component
    Object.const_set("TestSafeComponent", Class.new(ViewComponent::Base))
    
    generator = SwiftUIRails::Generators::StoriesGenerator.new(["TestSafe"])
    component = generator.send(:component_class)
    
    assert_equal TestSafeComponent, component
  ensure
    Object.send(:remove_const, "TestSafeComponent") if Object.const_defined?("TestSafeComponent")
  end
  
  test "rejects non-component classes" do
    # Create a non-component class
    Object.const_set("NotAComponent", Class.new)
    
    generator = SwiftUIRails::Generators::StoriesGenerator.new(["NotA"])
    component = generator.send(:component_class)
    
    # Should return nil for non-component classes
    assert_nil component
  ensure
    Object.send(:remove_const, "NotAComponent") if Object.const_defined?("NotAComponent")
  end
  
  test "handles missing component gracefully" do
    generator = SwiftUIRails::Generators::StoriesGenerator.new(["NonExistent"])
    component = generator.send(:component_class)
    
    # Should return nil for missing components
    assert_nil component
  end
  
  test "default story names when none provided" do
    generator = SwiftUIRails::Generators::StoriesGenerator.new(["MyComponent"])
    
    # Should provide default stories
    assert_equal ["default", "playground"], generator.send(:story_names)
  end
  
  test "prevents directory traversal" do
    dangerous_names = [
      "../../../etc/passwd",
      "..\\..\\..\\windows",
      "../../config/secrets"
    ]
    
    dangerous_names.each do |name|
      assert_raises Thor::Error do
        generator_for(name).validate_component_name!
      end
    end
  end
  
  test "handles special characters in file names" do
    generator = SwiftUIRails::Generators::StoriesGenerator.new(["My Component!!!"])
    
    # File name should be sanitized
    assert_equal "my_component", generator.send(:file_name)
  end

  test "emits configured defaults as safe Ruby literals" do
    dangerous_default = %q{"; Kernel.system("touch /tmp/stories-generator-pwned"); # #{interpolation}}
    props = {
      title: { type: String, default: dangerous_default },
      variant: { type: Symbol, default: :"quoted-variant" },
      enabled: { type: [TrueClass, FalseClass], default: false },
      optional: { type: String, default: nil },
      items: { type: Array, default: ["one", :two] },
      metadata: { type: Hash, default: { label: "O'Reilly" } }
    }
    component_class = Class.new(ViewComponent::Base)
    component_class.define_singleton_method(:swift_props) { props }
    Object.const_set("LiteralDefaultsComponent", component_class)

    run_generator ["LiteralDefaults", "playground"]

    assert_file "test/components/stories/literal_defaults_component_stories.rb" do |content|
      assert_nothing_raised { RubyVM::InstructionSequence.compile(content) }
      assert_includes content, "default: #{dangerous_default.inspect}"
      assert_includes content, 'default: :"quoted-variant"'
      assert_includes content, "default: false"
      assert_includes content, "default: nil"
      assert_includes content, 'default: ["one", :two]'
      assert_includes content, %(default: {:label => "O'Reilly"})
    end
  ensure
    Object.send(:remove_const, "LiteralDefaultsComponent") if Object.const_defined?("LiteralDefaultsComponent")
  end

  private

  def prepare_isolated_destination
    @isolated_destination_root = Dir.mktmpdir("stories-generator-", Rails.root.join("tmp").to_s)
    self.destination_root = @isolated_destination_root
  end

  def remove_isolated_destination
    return unless @isolated_destination_root && File.exist?(@isolated_destination_root)

    FileUtils.remove_entry(@isolated_destination_root)
  end

  def generator_for(name, *stories)
    SwiftUIRails::Generators::StoriesGenerator.new([name]).tap do |generator|
      # Thor 1.3 treats leading-dash values as CLI options before the
      # generator validator sees them. Set the parsed array directly so this
      # unit test exercises every hostile story name at the security boundary.
      generator.instance_variable_set(:@stories, stories)
    end
  end
end
