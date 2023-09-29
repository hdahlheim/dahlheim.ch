---
title: hakuna-cli
date: 2021-12-28
project_lang: GO
summary: CLI for the timetracking tool hakuna.ch
---

## About the project

The Hakuna CLI  is a simple Go application that interacts with the API of the time
tracking tool [hakuna.ch](https://hakuna.ch) for creating new timers and viewing time
entries or absences. The supported output formats are ASCII-table, JSON and CSV.

The CLI uses the cobra command parser and takes some inspiration
for displaying tables form the LXC CLI.

I used the Project for learning Go in the week between Christmas 2021 and new year of 2022.

You can find the code for hakuna-cli on [GitHub](https://github.com/hdahlheim/hakuna-go).

## How to use it

If you are a user of hakuna the easiest way to get started is [downloading](https://github.com/hdahlheim/hakuna-go/releases/tag/v1.0.1) the binary for your OS from GitHub and setting the two environment variables `HAKUNA_CLI_SUBDOMAIN` and `HAKUNA_CLI_API_TOKEN`.

```sh
export HAKUNA_CLI_SUBDOMAIN="my-company-subdomain"
export HAKUNA_CLI_API_TOKEN="xxxxxxxxxxxxxxxxxxxx"
# then you can use the CLI to start a timer
hakuna timer start --taskId=2 --note="Building cool stuff!"
```

If you don't feel like using enviroment variables you can also create a `.hakuna.yaml` config file.

```sh
cat << EOF > ~/.hakuna.yaml
subdomain: my-company-subdomain
api_token: xxxxxxxxxxxxxxxxxxxx
EOF
```
