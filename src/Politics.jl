module Politics

import Requests: get
using Requests

url = "https://www.googleapis.com/civicinfo/v2/representatives"
query = Dict("address" => "10028", "key" => "AIzaSyBKZFDfEfsZp6ZX-7N1cBWxza-DL7MnOgc")
res = get(url; query = query)

end
