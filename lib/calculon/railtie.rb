module Calculon
  class Railtie < Rails::Railtie
    initializer 'calculon.insert_into_active_record' do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.send(:include, Calculon)
      end
    end
  end
end
