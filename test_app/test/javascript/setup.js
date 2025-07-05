// Jest setup file
import '@testing-library/jest-dom'

// Mock MutationObserver which is used by Stimulus
global.MutationObserver = class {
  constructor(callback) {}
  disconnect() {}
  observe(element, options) {}
}