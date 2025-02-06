
```
[root@rocky8-market ~]# ssh-keygen -f ~/.ssh/jenkins-agent_ed25519 -t ed25519
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/jenkins-agent_ed25519.
Your public key has been saved in /root/.ssh/jenkins-agent_ed25519.pub.
The key fingerprint is:
SHA256:n3pBqTD/TsmGJSry3EaAdRR6KVOAJ2pAkL7H9d/6io4 root@rocky8-market
The key's randomart image is:
+--[ED25519 256]--+
|+o ..o+.         |
|o o oo..         |
|o. =+.o    .     |
|.o. .=o   o      |
|. o ...+So.      |
| . o  .oo*.o     |
|  o ... o.O.     |
|   + oo .=o.     |
|    oEoo.==.     |
+----[SHA256]-----+
[root@rocky8-market ~]# ls -al .ssh/
total 28
drwx------  2 root root  150 Feb  5 15:07 .
dr-xr-x---. 9 root root 4096 Feb  5 14:45 ..
-rw-------  1 root root  942 Dec  8 23:05 authorized_keys
-rw-------  1 root root  411 Aug 24 21:54 id_ed25519
-rw-r--r--  1 root root  100 Aug 24 21:54 id_ed25519.pub
-rw-------  1 root root  411 Feb  5 15:07 jenkins-agent_ed25519
-rw-r--r--  1 root root  100 Feb  5 15:07 jenkins-agent_ed25519.pub
-rw-r--r--  1 root root  550 Dec  8 22:46 known_hosts
[root@rocky8-market ~]# 
```

`Manage Credentials`

ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts
