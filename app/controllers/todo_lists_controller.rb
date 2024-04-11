# frozen_string_literal: true

class TodoListsController < ApplicationController
  # TODO: Define with team the best approach on encapsulating flows.
  before_action :authenticate_user

  before_action :set_todo_lists
  before_action :set_todo_list, except: [:index, :create]

  # TODO: This is a generic 404 error so I would move it to the application_controller
  rescue_from ActiveRecord::RecordNotFound do |not_found|
    render_json(404, todo_list: { id: not_found.id, message: 'not found' })
  end

  def index
    #TODO: If this gets too complex use a query object to encapsulte the query.
    # Would check with team on the preferred approach, using a specific gem, simple class with raw SQL, DTOs, etc
    todo_lists = @todo_lists.order_by(params).map(&:serialize_as_json)

    render_json(200, todo_lists: todo_lists)
  end

  def create
    # TODO: Abstract this into its own class/module to encapsulate registration logic and constraints.
    # We might need to run the create flow somewhere else so we can make sure its output is deterministic
    # CreateTodoListService.call(todo_list_params)

    todo_list = @todo_lists.create(todo_list_params)

    # I would actually leave this if like this, obviously using the mentioned service.
    # The benefit here is readability over DRYing the code up. I can with a glance understand what is happening and I don't have to go to any other file to check such a behavior
    if todo_list.valid?
      render_json(201, todo_list: todo_list.serialize_as_json)
    else
      render_json(422, todo_list: todo_list.errors.as_json)
    end
  end

  def show
    render_json(200, todo_list: @todo_list.serialize_as_json)
  end

  def destroy
    @todo_list.destroy

    render_json(200, todo_list: @todo_list.serialize_as_json)
  end

  def update
    @todo_list.update(todo_list_params)

    if @todo_list.valid?
      render_json(200, todo_list: @todo_list.serialize_as_json)
    else
      render_json(422, todo_list: @todo_list.errors.as_json)
    end
  end

  private

    def todo_lists_only_non_default? = action_name.in?(['update', 'destroy'])

    def set_todo_list
      @todo_list = @todo_lists.find(params[:id])
    end

    def todo_list_params
      params.require(:todo_list).permit(:title)
    end
end
