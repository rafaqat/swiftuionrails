# SimpleCov configuration
SimpleCov.start 'rails' do
  # Custom configuration for SwiftUI Rails
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
  add_filter '/.bundle/'
  
  # Group files for better organization
  add_group 'Components', 'app/components'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
  add_group 'Models', 'app/models'
  add_group 'JavaScript', 'app/javascript'
  add_group 'SwiftUI Rails', proc { |src| src.filename.include?('/swift_ui_rails/') }
  
  # Set coverage expectations (lowered initially to get baseline)
  minimum_coverage 50
  
  # Enable branch coverage
  enable_coverage :branch
  
  # Generate HTML report
  formatter SimpleCov::Formatter::HTMLFormatter
end