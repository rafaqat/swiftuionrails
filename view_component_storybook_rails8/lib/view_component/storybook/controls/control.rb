# frozen_string_literal: true

# Copyright 2025

module ViewComponent
  module Storybook
    module Controls
      class Control
        include ActiveModel::Validations

        validates :param, presence: true

        attr_reader :param, :name, :description, :default

        def initialize(param, default:, name: nil, description: nil)
          @param = param
          @default = default
          @name = name || param.to_s.humanize.titlecase
          @description = description
        end

        def to_csf_params
          # :nocov:
          raise NotImplementedError
          # :nocov:
        end

        def parse_param_value(value)
          # :nocov:
          raise NotImplementedError
          # :nocov:
        end
      end
    end
  end
end
# Copyright 2025
