## Head mobile controller.
## All mobile app controllers must hereditate from this.
class Mobile::MobileController < Mobile::MobileController
  layout "#{RAILS_ROOT}/app/views/mobile/layouts/main_mobile.html.erb"
  
  
end