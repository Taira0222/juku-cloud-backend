if defined?(Bullet)
  Bullet.enable = true
  Bullet.unused_eager_loading_enable = true

  # through の内部プリロードを無視
  Bullet.add_safelist type: :unused_eager_loading,
                      class_name: "User",
                      association: :user_class_subjects
  Bullet.add_safelist type: :unused_eager_loading,
                      class_name: "User",
                      association: :user_available_days
end
