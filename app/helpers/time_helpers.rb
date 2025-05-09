# frozen_string_literal: true

module TimeHelpers
  def time_ago_in_words(time)
    return unless time

    seconds = (Time.now - time).to_i
    case seconds
    when 0..59 then 'just now'
    when 60..3599 then "#{seconds / 60}m ago"
    when 3600..86_399 then "#{seconds / 3600}h ago"
    else "#{seconds / 86_400}d ago"
    end
  end
end
