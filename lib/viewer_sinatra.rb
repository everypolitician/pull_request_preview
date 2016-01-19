require 'github'

# Handles creating and updating viewer-sinatra preview pull requests.
class ViewerSinatra
  include Github

  attr_reader :everypolitician_data_pull_request
  attr_reader :countries_json_url

  def initialize(everypolitician_data_pull_request, countries_json_url)
    @everypolitician_data_pull_request = everypolitician_data_pull_request
    @countries_json_url = countries_json_url
  end

  def on_opened
    datasource = github.contents(viewer_sinatra_repo, path: 'DATASOURCE', ref: branch.ref)
    if Base64.decode64(datasource[:content]) != countries_json_url
      github.update_contents(
        viewer_sinatra_repo,
        'DATASOURCE',
        'Update DATASOURCE',
        datasource[:sha],
        countries_json_url,
        branch: branch_name
      )
    end
    create_pull_request
  end

  def on_merged
    datasource = github.contents(viewer_sinatra_repo, path: 'DATASOURCE')
    viewer_sinatra_pull_request = create_pull_request
    github.update_contents(
      viewer_sinatra_repo,
      'DATASOURCE',
      "Update DATASOURCE\n\n#{everypolitician_data_pull_request.html_url}\n" \
        "#{viewer_sinatra_pull_request[:html_url]}",
      datasource[:sha],
      countries_json_url
    )
    message = "I've updated DATASOURCE on master"
    github.add_comment(
      viewer_sinatra_repo,
      viewer_sinatra_pull_request[:number],
      message
    )
    github.close_pull_request(
      viewer_sinatra_repo,
      viewer_sinatra_pull_request[:number]
    )
  end

  def on_closed
    viewer_sinatra_pull_request = create_pull_request
    message = 'The parallel Pull Request in everypolitician-data was closed ' \
      'with unmerged commits.'
    github.add_comment(viewer_sinatra_repo, viewer_sinatra_pull_request.number, message)
    github.close_pull_request(viewer_sinatra_repo, viewer_sinatra_pull_request.number)
  end

  def branch_name
    "everypolitician-data-pr-#{everypolitician_data_pull_request.number}"
  end

  def branch
    @branch ||= begin
      ref = github.ref(viewer_sinatra_repo, "heads/#{branch_name}")
      fail Octokit::NotFound if ref.is_a?(Array)
      ref
    rescue Octokit::NotFound
      github.create_ref(
        viewer_sinatra_repo,
        "heads/#{branch_name}",
        github.branch(viewer_sinatra_repo, 'master').commit.sha
      )
    end
  end

  def pull_request_body
    @full_description ||= [
      "Commits:\n",
      everypolitician_data_pull_request.list_of_commit_messages,
      '',
      everypolitician_data_pull_request.html_url
    ].join("\n")
  end

  def existing_pull
    @existing_pull ||= github.pull_requests(
      viewer_sinatra_repo,
      head: [viewer_sinatra_repo.split('/').first, branch_name].join(':'),
      state: :all
    ).first
  end

  def existing_pull?
    !existing_pull.nil?
  end

  def create_pull_request
    if existing_pull?
      existing_pull
    else
      github.create_pull_request(
        viewer_sinatra_repo,
        'master',
        branch_name,
        everypolitician_data_pull_request.title,
        pull_request_body
      )
    end
  end

  def viewer_sinatra_repo
    @viewer_sinatra_repo ||= ENV.fetch(
      'VIEWER_SINATRA_REPO',
      'everypolitician/viewer-sinatra'
    )
  end
end
