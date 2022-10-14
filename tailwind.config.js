module.exports = {
  mode: 'jit',
  content: ['./{layouts,content}/**/*.html'],
  theme: {
    extend: {
      colors: {
        highlight: {
          DEFAULT: '#FA211F',
        },
      },
      fontFamily: {
        sans: [
          'Work Sans',
          'Inter',
          'system-ui',
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          'Roboto',
          '"Helvetica Neue"',
          'Arial',
          '"Noto Sans"',
          'sans-serif',
          '"Apple Color Emoji"',
          '"Segoe UI Emoji"',
          '"Segoe UI Symbol"',
          '"Noto Color Emoji"',
        ],
      },
    },
  },
  variants: {},
  plugins: [require('@tailwindcss/typography')],
}
