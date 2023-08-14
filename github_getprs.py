#!/usr/bin/python3
"""Print list of PRs requiring my input from Github."""
import json
import os

# https://github.com/PyGithub/PyGithub
# !pip install PyGithub
import github

# Assume we have a Github auth token stored in that file, with repo & PRs read access.
AUTH_TOKEN_FILE = os.path.join(os.getenv("HOME", ""), "github_auth_token.txt")
with open(AUTH_TOKEN_FILE, "r") as f:
    AUTH_TOKEN = f.read()
ORG = "reka-ai"
LOGIN = "c2mda"
MAX_TITLE_LEN = 60


def shorten_string(my_string: str) -> str:
    if len(my_string) > MAX_TITLE_LEN:
        return my_string[:MAX_TITLE_LEN] + "..."
    return my_string


def get_relevant_prs() -> list[dict[str, str]]:
    github_client = github.Github(auth=github.Auth.Token(AUTH_TOKEN))
    repos = github_client.get_organization(ORG).get_repos()
    valid_repos = [r for r in repos if not r.archived]  # Ignore archived repos.
    # Open PRs only.
    repo_pulls = {repo: repo.get_pulls(state="open") for repo in valid_repos}
    data = []
    for repo, pulls in repo_pulls.items():
        for pull in pulls:
            reviewer_logins = [r.login for r in pull.requested_reviewers]
            my_review_requested = LOGIN in reviewer_logins
            display_pull = my_review_requested or pull.user == LOGIN
            if display_pull:
                repo_name = repo.full_name.lstrip(ORG + "/")
                title = shorten_string(pull.title)
                author = pull.user.login
                status = "🔴" if my_review_requested else "✅"
                print_title = f"{status} {repo_name} {author}: {title}"
                data.append(dict(title=print_title, url=pull.html_url))
    return data


def main():
    # Toy data for quicker debugging:
    # print(json.dumps(
    #   [dict(title="🔴 somerepo someauthor: title of the pull request", url="http://www.example.com"),
    #    dict(title="✅ anotherrepo anotherauthor: another pull request title", url="http://www.google.com")
    #   ]))
    print(json.dumps(get_relevant_prs()))


if __name__ == "__main__":
    main()
