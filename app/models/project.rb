class Project

  include MongoMapper::Document

  ### PROPERTY ###

  key :name, String, :unique => true
  alias_method :title, :name
  key :description, String

  # callbacks
  key :num_ticket, Integer
  key :tag_counts, Hash
  key :current_milestone_name, String

  # TODO: need test about created_at and updated_at needed
  timestamps!

  ### EmbeddedDocument ###

  many :project_members
  include_errors_from :project_members

  ### Other Documents ###

  many :milestones, :dependent => :destroy
  many :tickets, :dependent => :destroy
  many :events, :dependent => :destroy

  key :current_milestone_id, ObjectId

  ### VALIDATIONS ###

  validates_true_for :project_members,
    :logic => lambda { have_one_admin },
    :message => 'need an admin'

  validates_true_for :same_project_members,
    :logic => lambda { only_once_each_member },
    :message => 'not several same member in project'

  validates_presence_of :name

  # TODO: avoid 2 users members of this project

  ### Callback ###

  # Callback about ProjectMember
  before_validation :update_project_admin
  before_validation :update_user_name

  before_save :update_current_milestone

  after_create :add_create_event

  after_update :add_update_event


  ### DM Compatibility ###
  def self.get(*args)
    self.find(*args)
  end


  ### ACCESSOR ###
  attr_writer :user_creator, :user_update

  ##
  # Return the next num ticket.
  # Update the num save in this project
  #
  def new_num_ticket
    old_num = num_ticket || 1
    self.num_ticket = old_num + 1
    save!
    old_num
  end

  ##
  # Check if use is member of this project
  #
  # @param[user] The user to test
  # @return[Boolean] member is or not on this project
  def has_member?(user_id)
    project_members.any? {|member| member.user_id.to_s == user_id.to_s }
  end


  ##
  # get project_member object where user is
  #
  # @params[User] user to fetch membership
  def project_membership(user)
    project_members.detect{|member| member.user_id == user.id }
  end

  ##
  # change function of som user in this project.
  # This change save project
  #
  # @params[Hash] hash with project_member.id and new function
  #               {project_member_id => function_id}
  # @returns[Boolean] true if change works false instead of
  def change_functions(member_function)
    return false unless member_function.values.any?{|m|
      Function.exists?(:project_admin => true,
                       :id => m)}
    member_function.each do |pm_id, function_id|
      project_members.detect{ |pm|
        pm.id.to_s == pm_id.to_s
      }.function_id = Function.find(function_id).id
    end
    save
  end

  ##
  # Ad user with a define function in project
  #
  # TODO: need spec about this function
  # We need a current milestone. See if we can define a milestone like current
  # it's made in lighthouse
  #
  # @params[user] User to add to this project
  # @params[function] Function on this project to this User
  def add_member(user, function)
    return if has_member?(user)
    project_members << ProjectMember.new(:user_name => user.login,
                                         :function_name => function.name,
                                         :project_admin => function.project_admin,
                                         :user => user,
                                         :function => function)
  end

  ##
  # check all milestone with expected_at in past.
  # No get current milestone
  #
  # TODO: need test unit
  #
  def outdated_milestones
    milestones.all(:conditions => {:expected_at => {'$lt' => Time.now},
                                   :_id => { '$ne' => (current_milestone ? current_milestone.id : 0)}},
                   :order => 'expected_at DESC')
  end

  ##
  # check all milestones with expected_at in futur
  # No get current milestone
  #
  # TODO: need test unit
  #
  def upcoming_milestones
    milestones.all(:conditions => { :expected_at => {'$gt' => Time.now},
                                    :id => {'$ne' => (current_milestone ? current_milestone.id : 0)}},
                   :order => 'expected_at ASC')
  end

  ##
  # check all milestone without expected_at
  # No get current milestone
  #
  # TODO: need test unit
  #
  def no_date_milestones
    milestones.all(:conditions => {:expected_at => nil,
                                    :id => { '$ne' => (current_milestone ? current_milestone.id : 0)}})
  end

  ##
  # check all tag of all tickets on this project.
  # Generate the tag_counts field
  #
  # This method is used in callback after ticket update.
  # Can be push in queue
  #
  def update_tag_counts
    tag_counts = {}
    tickets.all.map{|t| t.tags.to_a }.flatten.each do |tag|
      if tag_counts[tag]
        tag_counts[tag] += 1
      else
        tag_counts[tag] = 1
      end
    end
    self.tag_counts = tag_counts
    save!
  end

  class << self
    ##
    # Create a project with atribute and define user
    # with function define like project_admin
    #
    # @params[Hash] attributes to new Prject
    # @params[User] user define like first member of this project
    # @returns[Project] project initialize with attributes and user define
    #                   like first member with Function of project_admin
    def new_with_admin_member(attributes, user)
      @project = Project.new(attributes)
      @project.project_members << ProjectMember.new(:user => user,
                                                    :function => Function.admin)
      @project.user_creator = user
      @project
    end
  end


  ##
  # Check if project has one member define like admin
  def have_one_admin
    project_members.any? {|m| m.project_admin?}
  end

  def current_milestone
    Milestone.find(current_milestone_id)
  end

  def current_milestone=(milestone)
    self.current_milestone_id = milestone.id
    self.current_milestone_name = milestone.name
  end

  private

  ##
  # Add an event about project creation
  def add_create_event
    raise ArgumentError.new('Need define a user_creator in your code') unless @user_creator.is_a?(User)
    Event.create(:eventable => self,
                 :user => @user_creator,
                 :event_type => :created,
                 :project => self)
  end

  ##
  # Add an event about project update
  def add_update_event
    return unless @user_update.is_a?(User)
    Event.create(:eventable => self,
                 :user => @user_update,
                 :event_type => :updated,
                 :project => self)
  end

  def update_project_admin
    project_members.each do |pr|
      pr.function_name = pr.function.name
      pr.project_admin = pr.function.project_admin
    end
  end

  def update_user_name
    project_members.each do |pr|
      pr.user_name = pr.user.login
    end
  end

  def only_once_each_member
    project_members.map(&:user_id).uniq!.nil?
  end

  def update_current_milestone
    if !milestones.empty? && !current_milestone_id
      self.current_milestone = milestones.first
      self.current_milestone_name = self.current_milestone.name
    end
  end

end
