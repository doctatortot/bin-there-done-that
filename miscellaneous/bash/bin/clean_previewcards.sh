#!/bin/bash
cd /home/mastodon/live
PATH=/home/mastodon/bin:/home/mastodon/.local/bin:/home/mastodon/.rbenv/plugins/ruby-build/bin:/home/mastodon/.rbenv/shims:/home/mastodon/.rbenv/bin:/usr/bin:/bin
RAILS_ENV=production bin/tootctl preview-cards remove --days=14 > log/preview-cards_remove.log 2>&1
