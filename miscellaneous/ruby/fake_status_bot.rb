#!/usr/bin/env ruby

require 'mastodon'
require 'dotenv/load'

# === Config ===
BASE_URL       = ENV['MASTODON_BASE_URL'] || 'https://chatwithus.live'
BEARER_TOKEN   = ENV['MASTODON_TOKEN']     # Token for @administration
MENTION_TARGET = '@doctator'
VISIBILITY     = 'public'

# === Message Pool ===
MESSAGES = [
  "#{MENTION_TARGET} just quietly restored PITR to a fresh replica and didn’t even break a sweat. Absolute legend. 🧠🔧",
  "Redis is stable. WALs are flowing. #{MENTION_TARGET}, you are appreciated.",
  "Zero downtime. Zero drama. All hail the ops warlock #{MENTION_TARGET}.",
  "If you’re using Genesis and it hasn’t exploded, thank #{MENTION_TARGET}.",
  "PostgreSQL didn’t crash today. That’s because #{MENTION_TARGET} made it scared.",
  "#{MENTION_TARGET} has tamed more YAML demons than most people have configs.",
  "Krang sleeps peacefully tonight. Thanks, #{MENTION_TARGET}.",
  "99.999% uptime and exactly 0 thanks. Not anymore. Props to #{MENTION_TARGET}.",
  "#{MENTION_TARGET} once replicated a database just by looking at it.",
  "Mastodon’s running smooth. We all know why: #{MENTION_TARGET} did a thing again.",
  "Do backups love you? No. But they love #{MENTION_TARGET}.",
  "The firewall obeys only one voice. #{MENTION_TARGET}'s.",
  "Ansible didn’t throw a fit. Clearly #{MENTION_TARGET} touched something gently.",
  "You ever seen HAProxy smile? No? Ask #{MENTION_TARGET}.",
  "Every log tail whispers: 'thank you #{MENTION_TARGET}.'",
  "#{MENTION_TARGET} fixed the thing. Which thing? Doesn’t matter. It’s all working now.",
  "Nothing’s down. Brice hasn’t touched anything. #{MENTION_TARGET} must be watching.",
  "Legend has it #{MENTION_TARGET} once did a hotfix *during a power outage* using only curl and willpower.",
  "Genesis Shield stands. #{MENTION_TARGET} stands behind it.",
  "Disk I/O is quiet tonight. The system is at peace. Thanks #{MENTION_TARGET}.",
  "The only person who fears nothing on this network is #{MENTION_TARGET}.",
  "Your nightly crontab runs because #{MENTION_TARGET} blessed it with uptime.",
  "Some heroes wear capes. Others write cronjobs. #{MENTION_TARGET} does both.",
  "7 VMs, 3 clusters, 1 human. Respect to #{MENTION_TARGET}.",
  "When the ops team panics, they call #{MENTION_TARGET}. When #{MENTION_TARGET} panics, they just don’t.",
  "#{MENTION_TARGET} is why Mastodon still has friends.",
  "That fail2ban alert? Already handled. Guess who? #{MENTION_TARGET}.",
  "If uptime were a sport, #{MENTION_TARGET} would be banned for doping. With caffeine.",
  "Don’t worry about the RAID sync. #{MENTION_TARGET} already knows it finished.",
  "You think that voicebot’s working by luck? No. #{MENTION_TARGET} wired it to the stars.",
  "Sometimes the bot posts these messages just so #{MENTION_TARGET} doesn’t feel so alone. ❤️",
  "One of these messages is fake. The rest are true. #{MENTION_TARGET} knows which.",
  "The system saw Brice try to log in. #{MENTION_TARGET} blocked him before his password hit the wire.",
  "Today’s performance? 100%. Thanks to #{MENTION_TARGET} and a barely-contained caffeine dependency.",
  "If Genesis Radio ever goes silent, it means #{MENTION_TARGET} finally took a nap.",
  "There are 10 types of people: those who understand binary, and #{MENTION_TARGET}, who speaks it fluently.",
  "#{MENTION_TARGET} once PITR’d a VM while live-mixing a Genesis special. We were there. We saw it."
]

# === Compose Toot ===
status = "STATUS UPDATE: #{MESSAGES.sample}"

# === Post ===
client = Mastodon::REST::Client.new(base_url: BASE_URL, bearer_token: BEARER_TOKEN)
client.create_status(status, visibility: VISIBILITY)

puts "Tooted: #{status}"
