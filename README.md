Pooled CuRb gem
===============

A simple wrapper around curb to provide a pool of reusable HTTP connections.

Usage
-----

```
gem install pooled_curb
```

Or, with bundler

```ruby
gem 'pooled_curb'
```

Then use it:

```ruby
require 'pooled_curb'

PooledCurb.with_client do |curb|
  ...
end
```

Alternatively, issue HTTP commands directly:

```ruby
require 'pooled_curb'

response = PooledCurb.get("http://example.com")
```

License
-------

The MIT License (MIT)

Copyright (c) 2014 500px, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
