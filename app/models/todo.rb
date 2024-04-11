# frozen_string_literal: true

class Todo < ApplicationRecord
  attr_accessor :completed

  belongs_to :todo_list, required: true, inverse_of: :todos

  has_one :user, through: :todo_list

  # TODO: If this ever gets called with a DateTime param from outside this model, make sure the params is sanitized.
  scope :overdue, -> { incomplete.where('due_at <= ?', Time.current) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :incomplete, -> { where(completed_at: nil) }

  # TODO: This should be a class method. This scope results or purpose is determined by the input. I believe that a scope should have a consistent purpose
  scope :filter_by_status, ->(params) {
    case params[:status]&.strip&.downcase
    when 'overdue' then overdue
    when 'completed' then completed
    when 'incomplete' then incomplete
    else all
    end
  }

  # TODO: Might define a default_order as a scope that uses this scope as a building block. I wouldn't add any more logic to this one.
  # TODO: If we need product specific ordering maybe define concerns that implements that, that way we can just include it
  scope :order_by, ->(params) {
    order = params[:order]&.strip&.downcase == 'asc' ? :asc : :desc

    sort_by = params[:sort_by]&.strip&.downcase
    # TODO: if this is uuids then the ordering wouldn't be sequential. created_at might be a better default choice
    column_name = column_names.excluding('id').include?(sort_by) ? sort_by : 'id'

    order(column_name => order)
  }

  before_validation on: :update do
    # TODO: This simple functionality is very hard to read for what it does. I would move this conditional to a method that has a better name, something ensure_completeness
    # TODO: Abstract this regarding the completion status or step, might use a specific class for each status change, given that when you reach any state more actions than just saving a timestamp are needed.
    case completed
    when 'true' then complete
    when 'false' then incomplete
    end
  end

  validates :title, presence: true
  validates :due_at, presence: true, allow_nil: true
  validates :completed_at, presence: true, allow_nil: true

  def overdue?
    return false if !due_at || completed_at

    due_at <= Time.current
  end

  def incomplete?
    completed_at.nil?
  end

  def completed?
    !incomplete?
  end

  def status
    return 'completed' if completed?
    return 'overdue' if overdue?

    'incomplete'
  end

  def complete
    self.completed_at = Time.current unless completed?
  end

  def complete!
    complete

    self.save if completed_at_changed?
  end

  def incomplete
    self.completed_at = nil unless incomplete?
  end

  def incomplete!
    incomplete

    self.save if completed_at_changed?
  end

  def serialize_as_json
    as_json(except: [:completed], methods: :status)
  end

