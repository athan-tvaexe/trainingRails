class Score < ApplicationRecord
  # user là trường bắt buộc
  validates :user, presence: true

  # points là trường bắt buộc, phải là số nguyên và lớn hơn hoặc bằng 0
  validates :points, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
