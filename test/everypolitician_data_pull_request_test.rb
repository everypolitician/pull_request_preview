require 'test_helper'

describe EverypoliticianDataPullRequest do
  subject { EverypoliticianDataPullRequest.new(1) }

  it 'returns true if countries.json has been updated' do
    VCR.use_cassette('everypolitician_data_pull_request/files') do
      assert subject.updated_countries_json?
    end
  end

  it 'lists commit messages for pull request' do
    VCR.use_cassette('everypolitician_data_pull_request/commits') do
      expected = "- Faroe Islands: Refresh from upstream changes\n- Refresh countries.json"
      assert_equal expected, subject.list_of_commit_messages
    end
  end

  it 'allows accessing the underlying pull request' do
    VCR.use_cassette('everypolitician_data_pull_request/pull_request') do
      assert_equal "https://github.com/#{ENV['EVERYPOLITICIAN_DATA_REPO']}/pull/1", subject.html_url
      assert_equal 'Faroe islands test', subject.title
      assert_equal 1, subject.number
    end
  end
end
