db_config = YAML::load(File.read(File.join(Rails.root, "/config/database.yml")))

if db_config[Rails.env] && db_config[Rails.env]['adapter'] == 'mongodb'
  mongo = db_config[Rails.env]
  MongoMapper.connection = Mongo::Connection.new(mongo['hostname'],
                                                 mongo['port'] || 27017,
                                                 :slave_ok => true,
                                                :logger => Rails.logger)
  MongoMapper.database = mongo['database']
end
# module IdentityMapAddition
#   def self.included(model)
#     model.plugin MongoMapper::Plugins::IdentityMap
#   end
# end
#
# MongoMapper::Document.append_inclusions(IdentityMapAddition)
