# Pull Request Preview

Generates a pull request in 
[`everypolitician/viewer-sinatra`](https://github.com/everypolitician/viewer-sinatra)
if
[`countries.json`](https://github.com/everypolitician/everypolitician-data/blob/master/countries.json)
has been updated in a pull request on 
[`everypolitician/everypolitician-data`](https://github.com/everypolitician/everypolitician-data).

This is useful because the `viewer-sinatra` GitHub repo is currently
configured to generate a preview version of the
[EveryPolitician website](http://everypolitician.org/) (on Heroku)
whenever such a pull request is created.

So this app (`PullRequestPreview`) is triggered whenever a data pull request
event occurs on `everypolitician/everypolitician-data`.

If that pull request contains new (or updated) data, its `countries.json` file
will have been updated to point at those data-changing commits. `PullRequestPreview` creates a pull request on `viewer-sinatra` by updating
 `viewer-sinatra`'s [`DATASOURCE`](https://github.com/everypolitician/viewer-sinatra/blob/master/DATASOURCE)
file: it solely contains the URL to that specific version of `countries.json`. 

Because `countries.json` contains URLs that themselves link to
specific commits within that repo, each preview site is effectively previewing
the data relevant to the changes which caused the original data pull request.

Overall effect: a PR with new or updated data in `everypolitician-data` causes
a preview site to be spun up via `viewer-sinatra`.

For more information, see the
[bot blog on spinning up these preview sites](https://medium.com/@everypolitician/i-let-humans-peek-into-the-future-f4fe09eba59c).



## Development

### Install

Clone this repository

    git clone https://github.com/everypolitician/pull_request_preview
    cd pull_request_preview

Install dependencies

    bundle install

