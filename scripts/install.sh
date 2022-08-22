#!/bin/bash

echo "Please input the endpoint of okrs: "

read url

curl -LSs https://github.com/marigold-dev/okrs-git-hook/releases/download/0.1.0/commit-msg-macos-0.1.0.tar.gz -o .git/hooks/temp.tar.gz

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    tar -xf .git/hooks/temp.tar.gz -C .git/hooks/
elif [[ "$OSTYPE" == "darwin"* ]]; then
    tar xf .git/hooks/temp.tar.gz -C .git/hooks/
fi

rm .git/hooks/temp.tar.gz

chmod +x .git/hooks/commit-msg.exe

curl -Ss https://raw.githubusercontent.com/marigold-dev/okrs-git-hook/master/scripts/commit-msg -o .git/hooks/commit-msg

echo $url > .git/hooks/.config

echo "Hook installation done!"