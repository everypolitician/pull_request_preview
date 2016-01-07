require 'bundler/setup'
require 'base64'
require 'webhook_handler'
require 'dotenv'
require 'octokit'
Dotenv.load

class PullRequestPreview
  include WebhookHandler

  attr_reader :pull_request

  def github
    @github ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def handle_webhook
    request.body.rewind
    payload = JSON.parse(request.body.read)
    pull_request_number = payload['pull_request_url'].split('/').last
    self.class.perform_async(request.env['HTTP_X_EVERYPOLITICIAN_EVENT'], pull_request_number, payload['countries_json_url'])
  end

  def perform(event, pull_request_number, countries_json_url)
    @pull_request = github.pull(everypolitician_data_repo, pull_request_number)
    unless pull_request_updated_countries_json?
      warn 'No changes to countries.json detected'
      return
    end
    case event
    when 'pull_request_opened', 'pull_request_synchronize'
      datasource = github.contents(viewer_sinatra_repo, path: 'DATASOURCE', ref: branch.ref)
      if Base64.decode64(datasource.content) != countries_json_url
        github.update_contents(
          viewer_sinatra_repo,
          'DATASOURCE',
          'Update DATASOURCE',
          datasource.sha,
          countries_json_url,
          branch: branch_name
        )
      end
      find_or_create_pull_request(pull_request_title)
    when 'pull_request_merged'
      datasource = github.contents(viewer_sinatra_repo, path: 'DATASOURCE')
      viewer_sinatra_pull_request = find_or_create_pull_request(pull_request_title)
      github.update_contents(
        viewer_sinatra_repo,
        'DATASOURCE',
        "Update DATASOURCE\n\n#{everypolitician_data_pull_request.html_url}\n#{viewer_sinatra_pull_request.html_url}",
        datasource.sha,
        countries_json_url
      )
      message = "I've updated DATASOURCE on master"
      github.add_comment(viewer_sinatra_repo, viewer_sinatra_pull_request.number, message)
      github.close_pull_request(viewer_sinatra_repo, viewer_sinatra_pull_request.number)
    when 'pull_request_closed'
      viewer_sinatra_pull_request = find_or_create_pull_request(pull_request_title)
      message = "The parallel Pull Request in everypolitician-data was closed " \
        "with unmerged commits."
      github.add_comment(viewer_sinatra_repo, viewer_sinatra_pull_request.number, message)
      github.close_pull_request(viewer_sinatra_repo, viewer_sinatra_pull_request.number)
    end
  end

  def existing_pull
    @existing_pull ||= github.pull_requests(viewer_sinatra_repo).find do |pull|
      pull.head.ref == branch_name
    end
  end

  def existing_pull?
    !existing_pull.nil?
  end

  def find_or_create_pull_request(message)
    if existing_pull?
      existing_pull
    else
      github.create_pull_request(
        viewer_sinatra_repo,
        'master',
        branch_name,
        message,
        pull_request_body
      )
    end
  end

  def pull_request_body
    @full_description ||= [
      "Commits:\n",
      list_of_commit_messages,
      '',
      everypolitician_data_pull_request.html_url
    ].join("\n")
  end

  def list_of_commit_messages
    commits = github.pull_commits(
      everypolitician_data_repo,
      pull_request.number
    )
    messages = commits.map do |commit|
      commit.commit.message.lines.first.chomp
    end
    messages.map { |m| "- #{m}" }.join("\n")
  end

  def everypolitician_data_pull_request
    @pull_request ||= github.pull(
      everypolitician_data_repo,
      pull_request.number
    )
  end

  def pull_request_title
    everypolitician_data_pull_request.title
  end

  def pull_request_updated_countries_json?
    files = github.pull_files(everypolitician_data_repo, pull_request['number'])
    files.map { |f| f[:filename] }.flatten.uniq.include?('countries.json')
  end

  def branch
    @branch ||= begin
      ref = github.ref(viewer_sinatra_repo, "heads/#{branch_name}")
      fail Octokit::NotFound if ref.is_a?(Array)
      ref
    rescue Octokit::NotFound
      github.create_ref(viewer_sinatra_repo, "heads/#{branch_name}", github.branch(viewer_sinatra_repo, 'master').commit.sha)
    end
  end

  def branch_name
    "everypolitician-data-pr-#{pull_request[:number]}"
  end

  def everypolitician_data_repo
    @everypolitician_data_repo ||= ENV.fetch('EVERYPOLITICIAN_DATA_REPO', 'everypolitician/everypolitician-data')
  end

  def viewer_sinatra_repo
    @viewer_sinatra_repo ||= ENV.fetch('VIEWER_SINATRA_REPO', 'everypolitician/viewer-sinatra')
  end
end
