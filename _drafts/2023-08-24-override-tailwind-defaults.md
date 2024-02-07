
```js
const defaultTheme = require('tailwindcss/defaultTheme')

const colors = {
  transparent: "transparent",
  black: "#000",
  white: "#fff",
  red: {
    100: "#FFEFF1",
    500: "#FFAEB7",
    900: "#CC2A3D",
  },
  green: {
    100: "#EBF9F7",
    500: "#99E3D6",
    900: "#01957A",
  },
  blue: {
    100: "#F7F9FF",
    500: "#AEBDFF",
    900: "#2A49CC",
  },
}

const baseUnit = 16 // 16px = 1rem
const pxtorem = (px) => `${px / baseUnit}rem`

const spacing = [0, 1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 26, 32, 36, 38, 40, 48, 56, 62, 64, 72, 80, 96, 112, 128, 160, 256, 290, 320, 360, 460, 512]
  .reduce((spaces, space) => ({ ...spaces, [space]: pxtorem(space) }), {})

spacing["full"] = "100%"
spacing["px"] = "1px"

const fontsize = [8, 10, 11, 12, 13, 14, 16, 18, 20, 24, 32, 40, 64, 72]
  .reduce((fontsizes, fontsize) => ({ ...fontsizes, [fontsize]: pxtorem(fontsize) }), {})

fontsize["px"] = "1px"

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}',
    './app/components/**/*'
  ],
  theme: {
    extend: {
      colors: colors,
      spacing: spacing,
      fontSize: fontsize,
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
```
