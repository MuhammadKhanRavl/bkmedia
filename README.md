# bkmedia


![image](https://github.com/MuhammadKhanRavl/bkmedia/assets/142044230/ba0f6acd-1306-4cd0-a022-348b8a0c2764)

---
## Initial Setup 

**Vagrantfile**

The provided Vagrantfile completes sets up the three different VMs needed for the system in a private network. It defines static IP addresses and ports as follows:
- **Server:** `172.16.82.147:2222`
- **Client 1:** `172.16.82.148:2200`
- **Client 2:** `172.16.82.149:2233`

**SSH Key Setup**

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

**Sending Files**
You may need to send some files between servers for initial setup, which can be done using scp as follows:

```bash
scp test.txt vagrant@172.16.82.147.11:/home/vagrant/
```


---

## Usage of `deploy.sh`

The idea is to run `deploy.sh` in the same way as you would run `bkmedia.sh`. You pass in the arguments `-B`, `-R`, etc in the same way. Behind the scenes, `deploy.sh` will make a copy of the latest `packup.sh` file, which is your actual program, and run it on the server. 

---



