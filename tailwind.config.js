module.exports = {
  mode: 'jit',
  purge: [
    './layouts/**/*.html',
    './content/**/*.html'
  ],
  theme: {
    extend: {
      colors: {
        'highlight': '#fa211f'
      },
      fontFamily: {
        'sans': ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', '"Segoe UI"', 'Roboto', '"Helvetica Neue"', 'Arial', '"Noto Sans"', 'sans-serif', '"Apple Color Emoji"', '"Segoe UI Emoji"', '"Segoe UI Symbol"', '"Noto Color Emoji"']
      }
    }
  },
  variants: {},
  plugins: []
}
