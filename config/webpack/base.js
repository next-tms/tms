const { webpackConfig, merge } = require('@rails/webpacker')

bootstrapConfig = {
  module: {
    rules: [
      {
        test: /\.(scss)$/,
        use: [
          { loader: 'style-loader' },
          { loader: 'css-loader' },
          {
            loader: 'postcss-loader',
            options: {
              postcssOptions: {
                plugins: function () {
                  return [
                    require('autoprefixer')
                  ];
                }
              }
            }
          },
          { loader: 'sass-loader'}
        ]
      }
    ]
  }
}

module.exports = merge(bootstrapConfig, webpackConfig)
