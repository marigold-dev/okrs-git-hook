#!/bin/bash

echo "Please input the endpoint of okrs: "

read url


if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    curl -LSs https://github.com/marigold-dev/okrs-git-hook/releases/download/0.2.1/commit-msg-linux-0.2.1.tar.gz -o .git/hooks/temp.tar.gz
elif [[ "$OSTYPE" == "darwin"* ]]; then
    curl -LSs https://github.com/marigold-dev/okrs-git-hook/releases/download/0.2.1/commit-msg-macos-0.2.1.tar.gz -o .git/hooks/temp.tar.gz
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    tar -xf .git/hooks/temp.tar.gz -C .git/hooks/
elif [[ "$OSTYPE" == "darwin"* ]]; then
    tar xf .git/hooks/temp.tar.gz -C .git/hooks/
fi

rm .git/hooks/temp.tar.gz

curl -Ss https://raw.githubusercontent.com/marigold-dev/okrs-git-hook/master/scripts/commit-msg -o .git/hooks/commit-msg

chmod +x .git/hooks/commit-msg

echo $url > .git/hooks/.config

echo "Hook installation done!"