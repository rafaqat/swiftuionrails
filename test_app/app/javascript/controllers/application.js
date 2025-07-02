import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus   = application

// Note: All controllers are automatically loaded by stimulus-loading.js
// via the pin_all_from directive in importmap.rb
// No need for manual imports here

export { application }
