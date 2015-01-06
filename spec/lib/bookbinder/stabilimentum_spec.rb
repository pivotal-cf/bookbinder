require 'spec_helper'

module Bookbinder
  describe Spider::Stabilimentum do
    let(:referer) { double }
    let(:not_found?) { double }
    let(:url) { double }
    let(:html) { <<-HTML
        <h1>Fragment Targets</h1>
        <p id='existing-fragment-id'></p>
        <div name='existing-name-attribute'></div>

        <h1>Local Anchors</h1>
        <a href='#local'></a>
        <a href='#another-local'></a>
        <a href='#hot-dog'></a>

        <h1>Remote Anchors</h1>
        <a href='other-page.html#remote'></a>
        <a href='another-page.html#another-remote'></a>
        <a href='pork-pie-hats.html#hot-dog'></a>

        <h1>Remote Pages</h1>
        <a href='sad-page.html'></a>
        <a href='another-sad-page.html'></a>

        <h1>Empty Anchors</h1>
        <a href=''></a>
        <a></a>
      HTML
    }
    let(:page) { double(Anemone::Page, referer: referer, not_found?: not_found?, url: url, doc: Nokogiri::HTML(html)) }
    subject { described_class.new(page) }

    it 'delegates referer to its page' do
      expect(subject.referer).to eq(referer)
    end

    it 'delegates not_found? to its page' do
      expect(subject.not_found?).to eq(not_found?)
    end

    it 'delegates url to its page' do
      expect(subject.url).to eq(url)
    end

    describe 'having a target for a uri' do
      it 'has a target if its page includes the URI fragment as an ID' do
        expect(subject).to have_target_for(URI('#existing-fragment-id'))
      end

      it 'has a target if its page includes the URI fragment as a name attribute' do
        expect(subject).to have_target_for(URI('#existing-name-attribute'))
      end

      it 'does not have a target if its page does not include the URI fragment as an ID or attribute' do
        expect(subject).to_not have_target_for(URI('#weird-fragment'))
      end
    end

    describe 'the list of fragment identifiers' do
      context 'when asking for identifiers for the current page' do
        it 'only includes anchors with an anchor and no path' do
          local_uris = [
              '#local',
              '#another-local',
              '#hot-dog'
          ]
          expect(subject.fragment_identifiers(targeting_locally: true).map &:to_s).to match_array(local_uris)
        end
      end

      context 'when asking for identifiers for a different page' do
        it 'only includes anchors with an anchor and a path' do
          remote_uris = [
              'other-page.html#remote',
              'another-page.html#another-remote',
              'pork-pie-hats.html#hot-dog'
          ]
          expect(subject.fragment_identifiers(targeting_locally: false).map &:to_s).to match_array(remote_uris)
        end
      end

      context 'when the anchor is mal-formed' do
        let(:html) {
          <<-HTML
            <a href='remote%#place'></a>
            <a href='#local%place'></a>
            <a href='%'></a>
          HTML
        }
        let(:remote_fudged_uri) {Spider::Stabilimentum::FudgedUri.new('remote%', '#place', 'remote%#place')}
        let(:local_fudged_uri) {Spider::Stabilimentum::FudgedUri.new('', '#local%place', '#local%place')}

        it 'returns a fudged URI' do
          expect(subject.fragment_identifiers(targeting_locally: false)).to eq([remote_fudged_uri])
          expect(subject.fragment_identifiers(targeting_locally: true)).to eq([local_fudged_uri])
        end
      end
    end
  end
end

