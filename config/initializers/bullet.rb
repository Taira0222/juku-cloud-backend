if defined?(Bullet)
  Bullet.enable = true
  Bullet.n_plus_one_query_enable = true
  Bullet.unused_eager_loading_enable = false
  Bullet.counter_cache_enable = false

  # through の内部プリロードを無視
  Bullet.add_safelist type: :unused_eager_loading,
                      class_name: "User",
                      association: :user_class_subjects
  Bullet.add_safelist type: :unused_eager_loading,
                      class_name: "User",
                      association: :user_available_days

  Bullet.add_safelist type: :unused_eager_loading,
                      class_name: "User",
                      association: :teachable_subjects
end
