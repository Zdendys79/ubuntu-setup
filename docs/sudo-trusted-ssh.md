# sudo without a password for trusted SSH key sessions (step 11)

`sudo` asks for no password when the caller is logged in over SSH with a public key (or
an SSH certificate) from a trusted network - the LAN or Tailscale. Every other case (local
console, desktop session, password SSH login, SSH from the internet) still asks for the
password.

## How it works

- `/etc/pam.d/sudo` and `/etc/pam.d/sudo-i` get, before `@include common-auth`:
  `auth sufficient pam_exec.so quiet /usr/local/sbin/sudo-trusted-ssh`
- `sudo-trusted-ssh` (Python, run by PAM as root) checks the process that called it (sudo):
  1. its real user and its logind session (from the cgroup `session-N.scope` - a user
     cannot move a process into another session),
  2. the session: `Service=sshd`, the same user, `RemoteHost` inside a network listed in
     `/etc/sudo-trusted-ssh/networks`,
  3. the journal of the session leader (`sshd-session`) holds
     `Accepted publickey for <user> from <RemoteHost>` - written by sshd, so the user
     cannot fake it.
- Success is logged: `journalctl -t sudo-trusted-ssh`. Failures stay silent and the normal
  password prompt follows.

## Trusted networks

`/etc/sudo-trusted-ssh/networks`, one CIDR per line (kept when the step runs again):
`192.168.7.0/24` (LAN), `100.64.0.0/10` and `fd7a:115c:a1e0::/48` (Tailscale).

## Limits

- tmux: a shell inside tmux belongs to the session that started the tmux server. A tmux
  started from a trusted SSH login keeps working without a password; one started at the
  console or by a system service (e.g. `tmux-claude-startup.service`) asks for it.
- The journal of the current boot is used; after a reboot a new SSH login is needed anyway.
- `sudo -n` (non-interactive) never runs PAM authentication in sudo-rs (Ubuntu 26.04), so it
  fails without a cached timestamp: use plain `sudo` - it passes without a tty and without
  a prompt.

## Remove

Delete the `sudo-trusted-ssh` line from `/etc/pam.d/sudo` and `/etc/pam.d/sudo-i`, then
`rm -r /usr/local/sbin/sudo-trusted-ssh /etc/sudo-trusted-ssh`.
