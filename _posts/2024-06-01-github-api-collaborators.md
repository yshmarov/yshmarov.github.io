---
layout: post
title: "Github API. Automatically add/remove collaborators for a repository"
author: Yaroslav Shmarov
tags: github api
thumbnail: /assets/thumbnails/github-logo.png
---

If you are selling a programming course, you will likely want to grant users automatic access to a private github repo after purchase.

In my case I want to **automatically** grant all paid [SupeRails.com](https://superails.com/) subscribers access to [github.com/yshmarov/superails](https://github.com/yshmarov/superails). I want to remove repository access for users whose subscription has expired.

![github-access-superails-source-code](/assets/images/github-access-superails-source-code.png)

To access the Github API with Ruby we can use [gem Octokit](https://github.com/octokit/octokit.rb). Weird name, huh?

First, [create](https://github.com/settings/personal-access-tokens/new) a [personal access token](https://github.com/settings/tokens?type=beta).

![github-list-token](/assets/images/github-list-tokens.png)

Be sure to grant the token access to **Administration**!

![github-token-administration-rights](/assets/images/github-token-administration-rights.png)

Now you can interact with the [Github Collaborators API](https://docs.github.com/en/rest/collaborators/collaborators?apiVersion=2022-11-28#list-repository-collaborators):

```ruby
client = Octokit::Client.new(access_token: "github_pat_your_secret")
owner = 'yshmarov'
repo = 'superails'
# grant/remove access to:
username = 'secretpray'

# Get the list of collaborators
client.collaborators("#{owner}/#{repo}")
# Add collaborator
client.add_collaborator("#{owner}/#{repo}", username)
# Get the list of repository invitations
invitations = client.repository_invitations("#{owner}/#{repo}")
pending_invitations = invitations.map { |inv| { login: inv.invitee.login, email: inv.invitee.email } }
```

When removing a collaborator, be sure to remove an invitation, if the user has not yet accepted the invitation!

```ruby
# Remove collaborator
# ensure that there is no pending invitation
# there is no way to remove invitation by username
invitations = client.repository_invitations("#{owner}/#{repo}")
invitation = invitations.find { |inv| inv.invitee.login == username }
client.delete_repository_invitation("#{owner}/#{repo}", invitation.id) if invitation
# finally, remove collaborator
client.remove_collaborator("#{owner}/#{repo}", username)
```

Double check! View the users in the Github UI who have access/are invited to your repository inside `/settings/access` (`https://github.com/owner/repo/settings/access`):

![github-view-users-with-access-to-a-repo](/assets/images/github-view-users-with-access-to-a-repo.png)

That's it!
