module Merb
  module GlobalHelpers

    def title_project
      ret = "Oupsnow" 
      ret += " : #{@project.name}" if @project && !@project.name.blank?
      ret
    end

    def title_header
      ret = "Oupsnow"
      ret += " - #{@project.name}" if @project && !@project.name.blank?
      ret += " : #{@title}" if @title
      ret
    end

    def authenticated?
      session.user
    end

    def admin?(project)
      authenticated? && (session.user.global_admin? || session.user.admin?(project))
    end

    def global_admin?
      authenticated? && session.user.global_admin?
    end

    def sub_menu
    end

    def current_or_not(bool)
      bool ? "active" : ""
    end

    def overview_current
      current_or_not(@request.params[:controller] == 'projects' &&
                    @request.params[:action] == 'overview')
    end

    def milestone_current
      current_or_not(@request.params[:controller] == 'milestones')
    end

    def tickets_current
      current_or_not((@request.params[:controller] == 'tickets' && @request.params[:action] != 'new' && !@new_ticket) ||
                     @request.params[:controller] == 'ticket_updates')
    end

    def projects_current
      current_or_not(@request.params[:controller] == 'projects' &&
                    @request.params[:action] != 'overview' &&
                    @request.params[:action] != 'edit' &&
                    @request.params[:action] != 'delete')
    end

    def tickets_new_current
      current_or_not((@request.params[:controller] == 'tickets' &&
                    @request.params[:action] == 'new') || (@ticket_new))
    end

    def settings_current
      current_or_not( @request.params[:controller] =~ /settings\/\S+/ ||
                    (@request.params[:controller] == 'projects' && (@request.params[:action] == 'edit' || @request.params[:action] == 'delete')))
    end

    def textilized(text)
      text = "" if text.nil?
      RedCloth.new(text).to_html
    end

    def tag_cloud(tags, classes)
      return if tags.empty?

      max_count = 0
      tags.each { |key, value| max_count = value.size if value.size > max_count }

      tags.each do |tag_id, tagging|
        if max_count > 1
          index = ((tagging.size / max_count) * (classes.size - 1)).round
        else
          index = 0
        end
        yield Tag.get(tag_id), classes[index]
      end
    end

  end
end
