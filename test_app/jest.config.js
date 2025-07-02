module.exports = {
  testEnvironment: 'jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/app/javascript/$1'
  },
  testMatch: [
    '<rootDir>/test/javascript/**/*.test.js',
    '<rootDir>/test/javascript/**/*_test.js'
  ],
  setupFilesAfterEnv: ['<rootDir>/test/javascript/setup.js'],
  moduleDirectories: ['node_modules', 'app/javascript'],
  transform: {
    '^.+\\.js$': 'babel-jest'
  }
}