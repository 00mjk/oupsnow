class Project
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :nullable => false, :unique => true
  property :description, Text

  has n, :tickets
  has n, :members 
  has n, :users, :through => :members
  has n, :functions, :through => :members

end
