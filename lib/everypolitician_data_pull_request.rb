require 'github'

# Wrapper around everypolitician-data pull request that we want to preview.
class EverypoliticianDataPullRequest
  include Github

  attr_reader :pull_request_number

  def initialize(pull_request_number)
    @pull_request_number = pull_request_number
  end

  def pull_request
    @pull_request ||= github.pull(everypolitician_data_repo, pull_request_number)
  end

  def updated_countries_json?
    files = github.pull_files(everypolitician_data_repo, pull_request_number)
    files.map { |f| f[:filename] }.flatten.uniq.include?('countries.json')
  end

  def list_of_commit_messages
    commits = github.pull_commits(
      everypolitician_data_repo,
      pull_request_number
    )
    messages = commits.map do |commit|
      commit.commit.message.lines.first.chomp
    end
    messages.map { |m| "- #{m}" }.join("\n")
  end

  def html_url
    pull_request[:html_url]
  end

  def title
    pull_request[:title]
  end

  def number
    pull_request_number
  end

  def everypolitician_data_repo
    @everypolitician_data_repo ||= ENV.fetch(
      'EVERYPOLITICIAN_DATA_REPO',
      'everypolitician/everypolitician-data'
    )
  end
end
