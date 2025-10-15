# 教科が9科目
CLASS_SUBJECTS_COUNT = 5
CLASS_SUBJECTS_COUNT.times { |i| ClassSubject.find_or_create_by!(name: i) }

# 曜日が7つ
AVAILABLE_DAYS_COUNT = 7
AVAILABLE_DAYS_COUNT.times { |i| AvailableDay.find_or_create_by!(name: i) }
