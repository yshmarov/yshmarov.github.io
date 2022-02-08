---
layout: post
title: Push to github without re-entering password (connect SSH key)
author: Yaroslav Shmarov
tags: github git ssh
thumbnail: https://e7.pngegg.com/pngimages/951/741/png-clipart-secure-shell-ssh-keygen-computer-servers-computer-network-computer-software-shell-text-computer.png
---

**I hate re-entering the password when pushing to Github!**

Workaround: SSH connection!

* ### 1 Create an SSH key in your local terminal

```
ssh-keygen -t ed25519 -C "yshmarov@gmail.com"
```

You don't have to type in a password. Just press `Enter`

![1 generate ssh](assets/2020-10-05-aws-cloud9-github-ssh/1 generate ssh.png)

* ### 2 Start ssh agent, "Use" the generated key (in my case `id_ed25519`):

```
eval `ssh-agent -s`
ssh-add ~/.ssh/id_ed25519.pub
```

![2 use generated ssh key](assets/2020-10-05-aws-cloud9-github-ssh/2 use generated ssh key.png)

* ### 3 Open the key file 

![3 open generated ssh key](assets/2020-10-05-aws-cloud9-github-ssh/3 open generated ssh key.png)

* ### 4 Copy everything from the file

![4 copy generated ssh](assets/2020-10-05-aws-cloud9-github-ssh/4 copy generated ssh.png)

* ### 5 Paste the key to [github SSH creator](https://github.com/settings/ssh/new), give it any name

![5 paste ssh to github](assets/2020-10-05-aws-cloud9-github-ssh/5 paste ssh to github.png)

* ### 6 Check if you are connected to github. Console:

```
ssh -T git@github.com
```

![6 check connection](assets/2020-10-05-aws-cloud9-github-ssh/6 check connection.png)

* ### 7 Connect to remote repo via SSH

Type `git remote -v`

If you're updating to use HTTPS, your URL might look like:

```
https://[github]/USERNAME/REPOSITORY.git
```

If you're updating to use SSH, your URL might look like:

```
git@github.com:USERNAME/REPOSITORY.git
```

To switch remote URLs from HTTPS to SSH type:

```
git remote set-url origin git@github.com:USERNAME/REPOSITORY.git
git remote set-url origin git@github.com:yshmarov/REPOSITORY.git
```

When creating a remote, make sure you "clone with SSH" instead of "clone with HTTPS".

That's it! Next time you `git push` anything, it should authenticate automatically, and you'll not have to enter your credentials on C9 again.

****

P.S. If for some reason some of your commits are anonymous, you will want to run something like this in the console:

```sh
git config --global user.name "Yaro"
git config --global user.email yshmarov@gmail.com
```
