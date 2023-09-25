# System Overview

![image](https://github.com/MuhammadKhanRavl/bkmedia/assets/142044230/95fb35cb-5c4f-437d-a28e-b837f19ffd20)


# Setting up Environment 

### Vagrantfile

The provided Vagrantfile completes sets up the three different VMs needed for the system in a private network. It defines static IP addresses and ports as follows:
- **Server:** `172.16.82.147`
- **Client 1:** `172.16.82.148`
- **Client 2:** `172.16.82.149`

The VMs can be started up using `vagrant up`. Before running this, ensure that there is no `.vagrant` folder present in the directory, as this can sometimes cause conflicts. 


### SSH Key Setup

To setup the SSH keys onto the clients, first log into the server as follows:

```bash
vagrant ssh server
```

Then, generate a new SSH key pair:

```bash
ssh-keygen
```

Then, copy the key to the clients as follows:

```bash
ssh-copy-id vagrant@172.16.82.148
```

```bash
ssh-copy-id vagrant@172.16.82.149
```

It will ask you for a password, which by default is `vagrant`. After this, a password won't be needed. 


### Sending Files

You may need to send some files between servers for initial setup, which can be done using scp as follows:

```bash
vagrant scp "./apple.txt" "client1:/home/vagrant/backups"
```


### Usage of `deploy.sh`

The idea is to run `deploy.sh` in the same way as you would run `bkmedia.sh`. You pass in the arguments `-B`, `-R`, etc in the same way. Behind the scenes, `deploy.sh` will make a copy of the latest `packup.sh` file, which is your actual program, and run it on the server. 


