# Copyright 2025
# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

# Rails.application.configure do
#   config.content_security_policy do |policy|
#     policy.default_src :self, :https
#     policy.font_src    :self, :https, :data
#     policy.img_src     :self, :https, :data, :blob
#     policy.object_src  :none
#     policy.script_src  :self, :https, :unsafe_inline, 'https://unpkg.com', 'https://cdnjs.cloudflare.com'
#     policy.style_src   :self, :https, :unsafe_inline # Required for Tailwind
#     policy.connect_src :self, :https, "ws://localhost:*" if Rails.env.development?
#     # Specify URI for violation reports
#     # policy.report_uri "/csp-violation-report-endpoint"
#   end

#   # Generate session nonces for permitted importmap, inline scripts, and inline styles.
#   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
#   config.content_security_policy_nonce_directives = %w[script-src]

#   # Report violations without enforcing the policy in development
#   config.content_security_policy_report_only = Rails.env.development?
# end
# Copyright 2025
