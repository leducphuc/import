class Group < ActiveRecord::Base
  has_many :teams
  has_many :group_employees, dependent: :destroy
  has_many :employees, through: :group_employees
  has_many :managers, through: :group_employees, source: :employee
  has_many :childrens, class_name: Group.name, foreign_key: :parent_id
  belongs_to :parent, class_name: Group.name
  has_many :projects, dependent: :destroy
  has_one :manager, class_name: User.name

  scope :divisions,->{where parent_id: nil}
  scope :division_has_employees, ->{joins(:employees).divisions.group :id}
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  normalize_attributes :name
  auto_strip_attributes :name, nullify: false, squish: true

  def self.standardize data
    unless data[:parent_name.to_s].nil?
      data[:parent_id] = Group.find_by(name: data[:parent_name.to_s]).id
    end
    data.delete :parent_name.to_s
    data
  end

  def division_name
    short_name.blank? ? name : short_name
  end

  private
  CSV_REJECT_ATTRIBUTES = ["sync_key"]
end
