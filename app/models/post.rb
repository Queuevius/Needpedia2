class Post < ApplicationRecord
  has_rich_text :content
  acts_as_taggable_on :tags
  ################################ Constants ############################
  POST_TYPE_AREA = 'area'.freeze
  POST_TYPE_PROBLEM = 'problem'.freeze
  POST_TYPE_PROPOSAL = 'proposal'.freeze
  POST_TYPE_IDEA = 'idea'.freeze
  POST_TYPE_LAYER = 'layer'.freeze
  POST_TYPE_SOCIAL_MEDIA = 'social_media'.freeze
  POST_TYPES = [
    POST_TYPE_AREA,
    POST_TYPE_PROBLEM,
    POST_TYPE_PROPOSAL,
    POST_TYPE_IDEA,
    POST_TYPE_LAYER,
    POST_TYPE_SOCIAL_MEDIA
  ].freeze

  GENERAL_AREA = ENV['GENERAL_AREA_ID']
  GENERAL_PROBLEM = ENV['GENERAL_PROBLEM_ID']
  ################################ Relationships ########################
  belongs_to :user, optional: true
  belongs_to :parent_area, class_name: 'Post', foreign_key: :area_id, optional: true
  has_many :child_posts, class_name: 'Post', foreign_key: :area_id, dependent: :destroy

  belongs_to :problem, class_name: 'Post', foreign_key: :problem_id, optional: true
  has_many :ideas, class_name: 'Post', foreign_key: :problem_id, dependent: :destroy

  belongs_to :parent_post, class_name: 'Post', foreign_key: :post_id, optional: true
  has_many :layers, class_name: 'Post', foreign_key: :post_id, dependent: :destroy

  has_many :comments, as: :commentable, dependent: :destroy

  has_many :flags, as: :flagable, dependent: :destroy

  has_many :likes, as: :likeable, dependent: :destroy

  has_many :shares, as: :shareable, dependent: :destroy

  ############################### Validations ###########################
  validates :title, presence: true
  validates :post_type, presence: true, inclusion: { in: POST_TYPES }
  validates :area_id, presence: true, if: proc { |s| s.post_type == POST_TYPE_PROBLEM || s.post_type == POST_TYPE_PROPOSAL }
  validates :problem_id, presence: true, if: proc { |s| s.post_type == POST_TYPE_IDEA }
  # validates :post_id, presence: true, if: proc { |s| s.post_type == POST_TYPE_LAYER }

  ############################### Scopes ################################

  scope :posts_feed, -> { where.not('post_type IN (?)', [POST_TYPE_IDEA, POST_TYPE_LAYER]) }
  scope :area_posts, -> { where(post_type: POST_TYPE_AREA) }
  scope :problem_posts, -> { where(post_type: POST_TYPE_PROBLEM) }
  scope :proposal_posts, -> { where(post_type: POST_TYPE_PROPOSAL) }
  scope :idea_posts, -> { where(post_type: POST_TYPE_IDEA) }
  scope :layer_posts, -> { where(post_type: POST_TYPE_LAYER) }

  ############################### Methods ################################
  def parent_post_id
    area_id
  end
end
