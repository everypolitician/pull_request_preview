require 'bundler/setup'
require 'base64'
require 'webhook_handler'
require 'dotenv'
require 'octokit'
Dotenv.load

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'everypolitician_data_pull_request'
require 'viewer_sinatra'

class PullRequestPreview
  include WebhookHandler

  def handle_webhook
    request.body.rewind
    payload = JSON.parse(request.body.read)
    pull_request_number = payload['pull_request_url'].split('/').last
    self.class.perform_async(request.env['HTTP_X_EVERYPOLITICIAN_EVENT'], pull_request_number, payload['countries_json_url'])
  end

  def perform(event, pull_request_number, countries_json_url)
    everypolitician_data_pull_request = EverypoliticianDataPullRequest.new(pull_request_number)
    viewer_sinatra = ViewerSinatra.new(everypolitician_data_pull_request, countries_json_url)
    unless everypolitician_data_pull_request.updated_countries_json?
      warn 'No changes to countries.json detected'
      return
    end
    case event
    when 'pull_request_opened', 'pull_request_synchronize'
      viewer_sinatra.on_opened
    when 'pull_request_merged'
      viewer_sinatra.on_merged
    when 'pull_request_closed'
      viewer_sinatra.on_closed
    end
  end
end
