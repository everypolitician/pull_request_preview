# Pull Request Preview

Run a [`everypolitician/viewer-sinatra`](https://github.com/everypolitician/viewer-sinatra)-based staging server for open [`everypolitician/everypolitician-data`](https://github.com/everypolitician/everypolitician-data) pull requests.

* if
[`countries.json`](https://github.com/everypolitician/everypolitician-data/blob/master/countries.json)
has been updated in a pull request on 
[`everypolitician/everypolitician-data`](https://github.com/everypolitician/everypolitician-data), generate a pull request in 
[`everypolitician/viewer-sinatra`](https://github.com/everypolitician/viewer-sinatra) 

* if a pull request on `everypolitician/everypolitician-data` closes (perhaps it's been merged too), shut down the preview site associated with it.


## Preview sites for data changes

Effectively this app (`PullRequestPreview`) is passing activity on pull requests
on the `everypolitician-data` repo onto `viewer-sinatra`. 

This is useful because the `viewer-sinatra` GitHub repo is currently
configured to generate a preview version of the
[EveryPolitician website](http://everypolitician.org/) (on Heroku)
whenever such a pull request is created.

So this app is triggered whenever a data pull request
event occurs on `everypolitician/everypolitician-data`.

If that pull request contains new (or updated) data, its `countries.json` file
will have been updated to point at those data-changing commits. `PullRequestPreview` creates a pull request on `viewer-sinatra` by updating
 `viewer-sinatra`'s [`DATASOURCE`](https://github.com/everypolitician/viewer-sinatra/blob/master/DATASOURCE)
file: that file solely contains the URL to that specific version of
`countries.json`.

Because `countries.json` itself contains URLs that link to specific commits
within the data repo, each preview site is effectively previewing the data
relevant to the changes which caused the original data pull request.

Overall effect: a PR with new or updated data in `everypolitician-data` causes
a preview site to be spun up via `viewer-sinatra`.

For more information, see the
[bot blog on spinning up these preview sites](https://medium.com/@everypolitician/i-let-humans-peek-into-the-future-f4fe09eba59c).


## Webhook

This app expects to be triggered by a GitHub-style webhook from the
EveryPolitician webhook manager: see
[more about EveryPolitician webhooks](https://medium.com/@everypolitician/i-webhooks-pass-it-on-703e35e9ee93).

## Development

### Install

Clone this repository

    git clone https://github.com/everypolitician/pull_request_preview
    cd pull_request_preview

Install dependencies

    bundle install

