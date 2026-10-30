# Create a New Sudo User on Arch Linux

These commands create a new user, set their password, add them to the `wheel` group, and enable `sudo` access.

Run them as `root` or from an account that already has sudo access.

## Fish shell

Copy and paste the entire block:

```fish
read -P "Username: " username
read -sP "Password: " password
echo

sudo useradd -m -G wheel -s /bin/bash $username
echo "$username:$password" | sudo chpasswd

sudo sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo
echo "User '$username' created successfully."
echo "The user has sudo access through the wheel group."
```

If you are already logged in as `root`, remove `sudo` from the commands:

```fish
read -P "Username: " username
read -sP "Password: " password
echo

useradd -m -G wheel -s /bin/bash $username
echo "$username:$password" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo
echo "User '$username' created successfully."
echo "The user has sudo access through the wheel group."
```

## Bash shell

Copy and paste the entire block:

```bash
read -rp "Username: " username
read -rsp "Password: " password
echo

sudo useradd -m -G wheel -s /bin/bash "$username"
echo "$username:$password" | sudo chpasswd

sudo sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo
echo "User '$username' created successfully."
echo "The user has sudo access through the wheel group."
```

If you are already logged in as `root`:

```bash
read -rp "Username: " username
read -rsp "Password: " password
echo

useradd -m -G wheel -s /bin/bash "$username"
echo "$username:$password" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo
echo "User '$username' created successfully."
echo "The user has sudo access through the wheel group."
```

## Verify the user

After creating the account, verify that it belongs to `wheel`:

```bash
id username
```

You should see `wheel` in the groups.

Then switch to the new user:

```bash
su - username
```

Test sudo:

```bash
sudo whoami
```

It should output:

```text
root
```

## Important

The `wheel` group must have this line enabled in `/etc/sudoers`:

```text
%wheel ALL=(ALL:ALL) ALL
```

It is safer to edit `/etc/sudoers` with `visudo` if you are manually changing it:

```bash
sudo visudo
```

Then uncomment:

```text
%wheel ALL=(ALL:ALL) ALL
```

If your Arch installation already has this line enabled, you don't need to modify `/etc/sudoers` at all.
