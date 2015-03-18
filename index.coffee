request = require "request"
cheerio = require "cheerio"
async   = require "async"

getIndex = (callback) ->
    rootUrl = "https://specimens.cancer.gov"
    searchUrl = "https://specimens.cancer.gov/ajax/search/"
    headers =
        "Host": "specimens.cancer.gov"
        "Connection": "keep-alive"
        "Accept": "*/*"
        "Origin": "https://specimens.cancer.gov"
        "X-Requested-With": "XMLHttpRequest"
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
        "Referer": "https://specimens.cancer.gov/search/?"
        "Accept-Encoding": "gzip, deflate"
        "Accept-Language": "en-US,en;q=0.8"
        "Cookie": "csrftoken=70q2kVe4AijDWsDgsqNCxKkL2sWVeoRb; sessionid=aa1e06bc4acd720b83cfdfac141b30b6"
    form = 
        "csrfmiddlewaretoken": "70q2kVe4AijDWsDgsqNCxKkL2sWVeoRb"
        "page": 0

    # request {url: rootUrl, method: "POST", headers: headers, form: form}, (err, resp, body) ->
    #     $ = cheerio.load(body)
    #     index = $("table.listing tbody tr td a").map (i, el) -> console.log $(el).attr "href"

    request {url: searchUrl, method: "POST", headers: headers, form: form}, (err, resp, body) ->
        $ = cheerio.load(body)
        index = $("table.listing tbody tr td a").map (i, el) ->
            return collection = {
                sourceUrl: "#{rootUrl}#{$(el).attr "href"}"
                name: $(el).text()
            }
        callback null, index.get()

annotateCollections = (callback) ->
    getIndex (err, index) ->
        annotateCollection = (collection, done) ->
            collection.visited = true
            done()
        queue = async.queue annotateCollection, 4
        queue.drain = -> callback null, index
        queue.push index

annotateCollections (err, index) ->
    console.log index[0]