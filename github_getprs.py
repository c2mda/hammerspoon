#!/usr/bin/python3
"""Print list of PRs requiring my input from Github."""
import json
import os
import sys

# https://github.com/PyGithub/PyGithub
# !pip install PyGithub
import github

# Assume we have a Github auth token stored in that file, with repo & PRs read access.
AUTH_TOKEN_FILE = os.path.join(os.getenv("HOME", ""), "github_auth_token.txt")
with open(AUTH_TOKEN_FILE, "r") as f:
    AUTH_TOKEN = f.read().strip()
ORG = "reka-ai"
LOGIN = "c2mda"
MAX_TITLE_LEN = 60


def shorten_string(my_string: str) -> str:
    if len(my_string) > MAX_TITLE_LEN:
        return my_string[:MAX_TITLE_LEN] + "..."
    return my_string


def get_relevant_prs() -> list[dict[str, str]]:
    data = []
    try:
        github_client = github.Github(auth=github.Auth.Token(AUTH_TOKEN))
        repos = github_client.get_organization(ORG).get_repos()
        valid_repos = [r for r in repos if not r.archived]  # Ignore archived repos.
        # Open PRs only.
        repo_pulls = {repo: repo.get_pulls(state="open") for repo in valid_repos}
        for repo, pulls in repo_pulls.items():
            for pull in pulls:
                reviewer_logins = [r.login for r in pull.requested_reviewers]
                my_review_requested = LOGIN in reviewer_logins
                my_pr = pull.user.login == LOGIN
                display_pull = my_review_requested or my_pr
                under_review = (
                    pull.requested_reviewers and pull.mergeable_state == "blocked"
                )
                working_on_it = (my_pr and not under_review)
                ready_to_merge = my_pr and pull.mergeable_state == "clean"
                requires_attention = (
                    (not my_pr and my_review_requested)
                    or (my_pr and not under_review)
                    or (my_pr and ready_to_merge)
                )
                if display_pull:
                    repo_name = repo.full_name.removeprefix(ORG + "/")
                    title = shorten_string(pull.title)
                    author = pull.user.login
                    if working_on_it:
                        status = "🚧"
                    elif ready_to_merge:
                        status = "✅"
                    elif requires_attention:
                        status = "🔴"
                    elif under_review:
                        status = "🔎"
                    else:
                        status = "🚧"
                    print_title = f"{status} {repo_name} {author}: {title}"
                    data.append(
                        dict(
                            title=print_title,
                            url=pull.html_url,
                            requires_attention=str(requires_attention),
                        )
                    )
    except Exception as e:
        print(f"Encountered exception {e} while checking PRs.", file=sys.stderr)
    return data


def main():
    # Toy data for quicker debugging:
    # print(json.dumps(
    #   [dict(title="🔴 somerepo someauthor: title of the pull request", url="http://www.example.com, requires_attention="True"),
    #    dict(title="✅ anotherrepo anotherauthor: another pull request title", url="http://www.google.com", requires_attention="False"))
    #   ]))
    print(json.dumps(get_relevant_prs()))


if __name__ == "__main__":
    main()
