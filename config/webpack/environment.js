const { environment } = require('@rails/webpacker')

// resolve-url-loader must be used before sass-loader
environment.loaders.get('sass').use.splice(-1, 0, {
  loader: 'resolve-url-loader'
})

// From: http://blog.blackninjadojo.com/ruby/rails/2019/03/01/webpack-webpacker-and-modules-oh-my-how-to-add-javascript-to-ruby-on-rails.html
const webpack = require('webpack');
environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    'window.jQuery': 'jquery',
    $: 'jquery',
    jQuery: 'jquery',
    Popper: ['popper.js', 'default'],
    Rails: ['@rails/ujs']
  })
)

module.exports = environment