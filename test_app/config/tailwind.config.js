const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/**/*.{rb,erb,html,js}',
    './lib/**/*.{rb,erb,html,js}',
    './test/**/*.{rb,erb,html,js}',
    // Include component files
    './app/components/**/*.{rb,erb,html,js}',
    './test/components/**/*.{rb,erb,html,js}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  safelist: [
    // Explicit purple color classes that were missing
    'bg-purple-400', 'bg-purple-500', 'bg-purple-600', 'bg-purple-700', 'bg-purple-800',
    'hover:bg-purple-400', 'hover:bg-purple-500', 'hover:bg-purple-600', 'hover:bg-purple-700', 'hover:bg-purple-800',
    // Explicit pink color classes that were missing
    'bg-pink-400', 'bg-pink-500', 'bg-pink-600', 'bg-pink-700', 'bg-pink-800', 'bg-pink-900',
    'hover:bg-pink-400', 'hover:bg-pink-500', 'hover:bg-pink-600', 'hover:bg-pink-700', 'hover:bg-pink-800', 'hover:bg-pink-900',
    // Explicit yellow and gray classes for buttons
    'bg-yellow-500', 'hover:bg-yellow-500', 'bg-gray-600', 'hover:bg-gray-600',
    'bg-yellow-400', 'hover:bg-yellow-400', 'bg-gray-500', 'hover:bg-gray-500',
    'bg-yellow-600', 'hover:bg-yellow-600', 'bg-gray-700', 'hover:bg-gray-700',
    // Explicit text color classes that were missing
    'text-purple-50', 'text-purple-100', 'text-purple-200', 'text-purple-300', 'text-purple-400', 'text-purple-500', 'text-purple-600', 'text-purple-700', 'text-purple-800', 'text-purple-900',
    'text-pink-50', 'text-pink-100', 'text-pink-200', 'text-pink-300', 'text-pink-400', 'text-pink-500', 'text-pink-600', 'text-pink-700', 'text-pink-800', 'text-pink-900',
    'text-indigo-50', 'text-indigo-100', 'text-indigo-200', 'text-indigo-300', 'text-indigo-400', 'text-indigo-500', 'text-indigo-600', 'text-indigo-700', 'text-indigo-800', 'text-indigo-900',
    // Base color names (without shade - defaults to 500)
    'bg-slate', 'bg-gray', 'bg-zinc', 'bg-neutral', 'bg-stone', 'bg-red', 'bg-orange', 
    'bg-amber', 'bg-yellow', 'bg-lime', 'bg-green', 'bg-emerald', 'bg-teal', 'bg-cyan', 
    'bg-sky', 'bg-blue', 'bg-indigo', 'bg-violet', 'bg-purple', 'bg-fuchsia', 'bg-pink', 'bg-rose',
    'text-slate', 'text-gray', 'text-zinc', 'text-neutral', 'text-stone', 'text-red', 'text-orange',
    'text-amber', 'text-yellow', 'text-lime', 'text-green', 'text-emerald', 'text-teal', 'text-cyan',
    'text-sky', 'text-blue', 'text-indigo', 'text-violet', 'text-purple', 'text-fuchsia', 'text-pink', 'text-rose',
    'hover:bg-slate', 'hover:bg-gray', 'hover:bg-zinc', 'hover:bg-neutral', 'hover:bg-stone', 'hover:bg-red',
    'hover:bg-orange', 'hover:bg-amber', 'hover:bg-yellow', 'hover:bg-lime', 'hover:bg-green', 'hover:bg-emerald',
    'hover:bg-teal', 'hover:bg-cyan', 'hover:bg-sky', 'hover:bg-blue', 'hover:bg-indigo', 'hover:bg-violet',
    'hover:bg-purple', 'hover:bg-fuchsia', 'hover:bg-pink', 'hover:bg-rose',
    'border-slate', 'border-gray', 'border-zinc', 'border-neutral', 'border-stone', 'border-red',
    'border-orange', 'border-amber', 'border-yellow', 'border-lime', 'border-green', 'border-emerald',
    'border-teal', 'border-cyan', 'border-sky', 'border-blue', 'border-indigo', 'border-violet',
    'border-purple', 'border-fuchsia', 'border-pink', 'border-rose',
    // Background colors for all standard Tailwind color palette with shades
    {
      pattern: /bg-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(50|100|200|300|400|500|600|700|800|900|950)/,
    },
    // Text colors with shades
    {
      pattern: /text-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(50|100|200|300|400|500|600|700|800|900|950)/,
    },
    // Hover states with shades
    {
      pattern: /hover:bg-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(50|100|200|300|400|500|600|700|800|900|950)/,
    },
    // Focus ring colors
    {
      pattern: /focus:ring-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(50|100|200|300|400|500|600|700|800|900|950)/,
    },
    // Border colors
    {
      pattern: /border-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(50|100|200|300|400|500|600|700|800|900|950)/,
    },
    // Additional utility classes that components might use
    'opacity-50', 'opacity-90', 'cursor-not-allowed', 'transition-colors', 'duration-200',
    'focus:outline-none', 'focus:ring-2', 'focus:ring-offset-2',
    'inline-flex', 'items-center', 'justify-center',
    'rounded-none', 'rounded-sm', 'rounded-md', 'rounded-lg', 'rounded-xl', 'rounded-full',
    'px-3', 'px-4', 'px-6', 'px-8', 'py-2', 'py-3', 'py-4',
    'text-xs', 'text-sm', 'text-base', 'text-lg', 'text-xl',
    'font-medium', 'font-semibold', 'font-bold',
    'hover:brightness-90', 'hover:brightness-110', 'brightness-90', 'brightness-110'
  ],
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}