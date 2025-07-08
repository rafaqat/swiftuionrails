require "spec_helper"
require "generator_spec"
require "generators/swift_ui_rails/component/component_generator"

RSpec.describe SwiftUIRails::Generators::ComponentGenerator, type: :generator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../tmp", __dir__)

  before do
    prepare_destination
  end

  describe "component generation" do
    context "with valid arguments" do
      it "creates component file with props" do
        run_generator ["UserCard", "name:String", "age:Integer"]

        assert_file "app/components/user_card_component.rb" do |content|
          assert_match(/class UserCardComponent < ApplicationComponent/, content)
          assert_match(/prop :name, type: String/, content)
          assert_match(/prop :age, type: Integer/, content)
        end
      end

      it "creates component spec file" do
        run_generator ["UserCard", "name:String"]

        assert_file "spec/components/user_card_component_spec.rb" do |content|
          assert_match(/RSpec.describe UserCardComponent/, content)
        end
      end

      it "handles namespaced components" do
        run_generator ["Admin::Dashboard", "title:String"]

        assert_file "app/components/admin/dashboard_component.rb" do |content|
          assert_match(/class DashboardComponent < ApplicationComponent/, content)
        end
      end
    end

    context "error handling" do
      it "handles missing component name" do
        # Thor handles missing required arguments
        output = capture(:stderr) { run_generator [] rescue nil }
        expect(output).to include("No value provided for required arguments")
      end

      it "validates invalid component names" do
        # Test starts with number - handled by self.start
        expect do
          SwiftUIRails::Generators::ComponentGenerator.start(["123Component"])
        end.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
        
        # Test forbidden keywords - exits with error
        expect { run_generator ["system"] }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end

      it "validates invalid prop definitions" do
        # Should exit with error
        expect { run_generator ["MyComponent", ":String"] }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    context "prop validation" do
      it "validates prop names" do
        # The validation should exit with error for reserved words
        expect { run_generator ["MyComponent", "class:String"] }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end

      it "sanitizes prop types" do
        # Invalid type should be sanitized to String with a warning
        # Note: The warning goes to Thor's shell, not captured stdout
        run_generator ["MyComponent", "data:invalid-type"]
        
        # Should default to String for invalid types
        assert_file "app/components/my_component_component.rb" do |content|
          assert_match(/prop :data, type: String/, content)
        end
      end
    end

    context "file conflict handling" do
      it "skips existing files by default" do
        # First run creates the file
        run_generator ["MyComponent"]
        assert_file "app/components/my_component_component.rb"
        
        # Get original content
        original_content = File.read(File.join(destination_root, "app/components/my_component_component.rb"))
        
        # Modify the file to ensure it's not overwritten
        File.write(File.join(destination_root, "app/components/my_component_component.rb"), 
                  original_content + "\n# MODIFIED")
        
        # Second run should skip and not overwrite
        run_generator ["MyComponent"]
        
        # Verify the modification is still there (file was not overwritten)
        assert_file "app/components/my_component_component.rb" do |content|
          assert_match(/# MODIFIED/, content)
        end
      end

      it "overwrites with --force option" do
        run_generator ["MyComponent"]
        
        # Add content to file to verify overwrite
        file_path = File.join(destination_root, "app/components/my_component_component.rb")
        original_content = File.read(file_path)
        File.write(file_path, original_content + "\n# Modified")
        
        # Run with force
        run_generator ["MyComponent", "--force"]
        
        # Should not contain the modification
        assert_file "app/components/my_component_component.rb" do |content|
          assert_no_match(/# Modified/, content)
        end
      end
    end
  end

  describe "security" do
    it "prevents code injection in component names" do
      malicious_names = [
        "Component\"; system('echo pwned')",
        "Component`echo pwned`",
        "Component$(echo pwned)",
        "Component && echo pwned"
      ]

      malicious_names.each do |name|
        # Component name validation now exits with error code
        expect { run_generator [name] }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end

    it "prevents code injection in prop definitions" do
      malicious_props = [
        "name:String; system('echo pwned')",
        "name:`echo pwned`",
        "name:$(echo pwned)"
      ]

      malicious_props.each do |prop|
        expect { run_generator ["MyComponent", prop] }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
      end
    end
  end
end