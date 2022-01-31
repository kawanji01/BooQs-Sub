const { environment } = require('@rails/webpacker')

// jQueryの導入；　参考；https://qiita.com/tatsuhiko-nakayama/items/b2f0c77e794ca8c9bd74
const webpack = require('webpack')
environment.plugins.prepend('Provide',
    new webpack.ProvidePlugin({
        $: 'jquery/src/jquery',
        jQuery: 'jquery/src/jquery'
    })
)
// jQueryの導入

module.exports = environment
