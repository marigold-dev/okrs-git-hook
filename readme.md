# Okrs-git-hook

This project is a git hook that help to work with an [OKRs organisation](https://www.atlassian.com/agile/agile-at-scale/okr). The goal is to link commits to an issue, allowing to follow the progress of a KR

# How it works ?

The hook will fetch a url (that you have to configure when installing the hook) that looks like this: `https://my.url.com/.../:repo-name`.
`https://my.url.com/...` is the url that you provide when you'll install the hook, and `:repo-name` is the name of repository you're working on, and it will be appended to the url to fetch the OKRs.
It expects the answer to looks like this:

```json
[
  {
    "id": 0,
    "objective": "My objective",
    "krs": [
      {
        "id": 0,
        "result": "My result",
        "issue_number": 12
      }
    ]
  }
]
```

Then it'll prompt the user with these informations so he can pick the objective and KR he's working on. In the end, it'll append to the commit message the issue number of the KR, which will mention the commit in the issue.

# How to install ?

Open a terminal at the root of your project, and run the following command, and provide a url when asked for

```bash
sh -c "$(curl -Ss https://raw.githubusercontent.com/marigold-dev/okrs-git-hook/master/scripts/install.sh)"
```

# How to develop ?

1. Clone the repository

```bash
git clone https://github.com/marigold-dev/okrs-git-hook
```

2. Open a terminal in the project

3. Create a switch

```bash
opam switch create . 4.14.0 --deps-only
```

4. Update the terminal

```bash
eval $(opam env)
```

5. Build the code

```bash
dune build
```

6. Voilà! You're ready!
