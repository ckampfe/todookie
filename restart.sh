#!/usr/bin/env sh

launchctl unload ~/Library/LaunchAgents/ckampfe.todookie.plist
launchctl load -w ~/Library/LaunchAgents/ckampfe.todookie.plist

