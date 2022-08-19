#!/bin/bash

echo "Please input the endpoint of okrs: "

read url

curl -Ss https://raw.githubusercontent.com/marigold-dev/okrs-git-hook/main/scipts/commit-msg.sh -o .git/hooks/commit-msg

curl -Ss https://raw.githubusercontent.com/marigold-dev/okrs-git-hook/main/scipts/commit-msg.sh -o .git/hooks/commit-msg.exe

echo $url > .git/hooks/.config