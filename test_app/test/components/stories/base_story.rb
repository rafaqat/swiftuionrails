class BaseStory
  class_attribute :story_definitions
  self.story_definitions = {}
  
  class << self
    def story(name, &block)
      story_definitions[name] = block
      
      define_method("story_#{name}") do
        @current_story = name
        @story_config = { controls: {}, layout: nil, component: nil }
        instance_eval(&block) if block_given?
        @story_config
      end
    end
    
    def component(klass)
      @component_class = klass
    end
  end
  
  def component(klass)
    @story_config[:component] = klass
  end
  
  def controls(&block)
    @controls_builder = ControlsBuilder.new
    @controls_builder.instance_eval(&block)
    @story_config[:controls] = @controls_builder.controls
  end
  
  def layout(name)
    @story_config[:layout] = name
  end
  
  class ControlsBuilder
    attr_reader :controls
    
    def initialize
      @controls = {}
    end
    
    def swift_text(name, default: "")
      @controls[name] = { type: :text, default: default }
    end
    
    def swift_select(name, options: [], default: nil)
      @controls[name] = { type: :select, options: options, default: default || options.first }
    end
    
    def swift_boolean(name, default: false)
      @controls[name] = { type: :boolean, default: default }
    end
    
    def swift_number(name, default: 0, min: nil, max: nil)
      @controls[name] = { type: :number, default: default, min: min, max: max }
    end
  end
end