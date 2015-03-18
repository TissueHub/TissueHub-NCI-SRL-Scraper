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
            request.get collection.sourceUrl, (err, resp, body) ->
                # collection.body = body
                $ = cheerio.load(body)

                collection.phenotypes = []
                collection.specimenTypes = []
                $("dt").map (i, el) ->
                    switch $(el).text()
                        when "Organ Site" then appendValues collection.phenotypes, $(el)
                        when "Histology / Tumor Type" then appendValues collection.phenotypes, $(el)
                        when "Specimen Type" then appendValues collection.specimenTypes, $(el)
                        when "Other Specimen Types in this Collection (if any)" then appendValues collection.specimenTypes, $(el)
                        when "Preservation Type" then appendValues collection.specimenTypes, $(el)
                collection.contactEmail = $(".contact.wrap a").filter((i, el) -> $(el).attr("href").match("mailto")).text()
                done()

        queue = async.queue annotateCollection, 4
        queue.drain = -> callback null, index
        queue.push index.slice 0,5

appendValues = (array, $el) ->
    values = $el.next().text().split(",")
    values.forEach (value) ->
        if value then array.push value.trim()

annotateCollections (err, index) ->
    console.log index.slice 0,5