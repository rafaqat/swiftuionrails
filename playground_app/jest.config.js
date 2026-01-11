module.exports = {
  testEnvironment: 'jsdom',
  testMatch: [
    '**/test/jest/**/*.test.js',
    '**/test/jest/**/*.spec.js'
  ],
  setupFilesAfterEnv: ['<rootDir>/test/jest/setup.js'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/app/javascript/$1'
  },
  transform: {
    '^.+\\.js$': 'babel-jest'
  },
  collectCoverageFrom: [
    'app/javascript/controllers/**/*.js',
    '!app/javascript/controllers/application.js',
    '!app/javascript/controllers/hello_controller.js'
  ],
  coverageDirectory: 'test/jest/coverage',
  verbose: true
};