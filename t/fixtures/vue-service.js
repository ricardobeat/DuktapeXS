const Vue = require('vue');
const ssr = require('vue-server-renderer')
const http = require('http')

const server = http.createServer((req, res) => {
  const app = new Vue({
    template: '<div>Hello World</div>'
  })
  const renderer = ssr.createRenderer();
  renderer.renderToString(app, (err, html) => {
    if (err) throw err
    res.end(html)
  })
})

server.listen(8088);
