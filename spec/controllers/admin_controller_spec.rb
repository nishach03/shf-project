require 'rails_helper'


RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, :type => :controller
end


RSpec.describe AdminController, type: :controller do

  include Warden::Test::Helpers

  include Devise::Test::ControllerHelpers

  # this will bypass Pundit policy access checks so logging in is not necessary
  before(:each) { Warden.test_mode! }

  after(:each) { Warden.test_reset! }

  let(:user) { create(:user) }

  let(:csv_header) { out_str = ''
  out_str << "'#{I18n.t('activerecord.attributes.membership_application.contact_email').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.membership_application.first_name').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.membership_application.last_name').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.membership_application.membership_number').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.membership_application.state').strip}',"
  out_str << "'#{I18n.t('activerecord.models.company.one').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.address.street').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.address.post_code').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.address.city').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.address.kommun').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.address.region').strip}',"
  out_str << "'#{I18n.t('activerecord.attributes.address.country').strip}'"
  out_str << "\n"
  out_str}


  describe '#export_ankosan_csv' do


    describe 'logged in as admin' do

      it 'content type is text/csv' do

        post :export_ansokan_csv

        expect(response.content_type).to eq 'text/plain'

      end


      it 'header line is correct' do

        post :export_ansokan_csv

        expect(response.body).to eq csv_header

      end


      describe 'with 0 membership applications' do

        it 'no membership applications has just the header' do

          post :export_ansokan_csv

          expect(response.body).to eq csv_header

        end

      end


      describe 'with 1 app for each membership state' do

        it 'includes all applications' do

          result_str = csv_header

          # create 1 application in each state
          MembershipApplication.aasm.states.each do |app_state|

            u = FactoryGirl.create(:user, email: "#{app_state.name}@example.com")

            m = FactoryGirl.create :membership_application,
                                   first_name:    "First#{app_state.name}",
                                   last_name:     "Last#{app_state.name}",
                                   contact_email: "#{app_state.name}@example.com",
                                   state:         app_state.name,
                                   user:          u

            member1_info = "#{m.contact_email},#{m.first_name},#{m.last_name},#{m.membership_number},"+ I18n.t("membership_applications.state.#{app_state.name}")

            result_str << member1_info + ','

            result_str << (m.company.nil? ? '' : '"' + m.company.name + '"')
            result_str << ','

            result_str << m.se_mailing_csv_str + "\n"

          end

          post :export_ansokan_csv

          expect(response.body).to match result_str

        end

      end


      describe 'includes mailing addresses' do

        def address_string(address)
          "#{address.street_address},#{address.post_code},#{address.city},#{address.kommun.name },#{address.region.name},#{address.country_postal}"
        end


        it 'uses the company name and  address for each member' do

          u1      = FactoryGirl.create(:user, email: "user1@example.com")
          c1      = FactoryGirl.create(:company)
          member1 = FactoryGirl.create :membership_application,
                                       first_name:     "u1",
                                       contact_email:  "u1@example.com",
                                       state:          :accepted,
                                       company_number: c1.company_number,
                                       user:           u1

          result_str = csv_header

          member1.update(membership_number: '1234567890')

          member1_info = "#{member1.contact_email},#{member1.first_name},#{member1.last_name},#{member1.membership_number},"+ I18n.t("membership_applications.state.#{member1.state}")

          result_str << member1_info + ','
          result_str << '"' + c1.name + '"' +','

          result_str << c1.se_mailing_csv_str + "\n"


          post :export_ansokan_csv

          expect(response.body).to match result_str

        end

      end


      describe 'error from send_data is rescued' do

        # status, location, response_body

        let(:error_message) {'Error. Error. Warning Will Robinson'}

        subject {allow(@controller).to receive(:send_data) {raise StandardError.new(error_message)}

        post :export_ansokan_csv
        }


        it 'redirects to back or the root path' do

          expect(subject).to redirect_to root_path

        end


        it "flashes an error :alert message" do

          error_flash_message = ["#{I18n.t('admin.export_ansokan_csv.error')} [#{error_message}]"]

          expect(subject.request.flash[:alert]).to_not be_nil
          expect(subject.request.flash[:alert]).to eq error_flash_message

        end

      end

    end

  end


end
