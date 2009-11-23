class Event

  include MongoMapper::Document

  ### PROPERTY ###

  key :user_name, String
  key :event_type, String

  ### Association ###

  key :user_id, ObjectId
  key :project_id, ObjectId

  # Polymorphic event
  key :eventable_type, String
  key :eventable_id, ObjectId

  belongs_to :user
  belongs_to :project
  belongs_to :eventable, :polymorphic => true, :dependent => :destroy

  # TODO: need test about created_at/updated_at needed
  timestamps!

  def short_description
    eventable.title
  end

  ##
  # get the class eventable in string pluralize
  def eventable_pluralize
    eventable.class.to_s.pluralize.downcase
  end


end
