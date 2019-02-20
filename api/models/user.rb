require 'date'

class User < ActiveRecord::Base
  def age
    DateTime.now.year - birth_date.year
  end
end
