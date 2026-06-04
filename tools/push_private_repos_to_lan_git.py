#!/usr/bin/env python3
"""Setup local git server repos and SSH key for passwordless push."""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import paramiko

HOST = "git-server.local"
USER = "git"
PASSWORD = "git"
REPO_ROOT = "/srv/git/repos"

PRIVATE_REPOS = [
    ("ai-lib-constitution", Path(r"D:\ai-lib-constitution")),
    ("ai-lib-plans", Path(r"D:\ai-lib-plans")),
    ("papers", Path(r"D:\rustapp\papers")),
    ("eos", Path(r"D:\rustapp\eos")),
    ("ai-lib-gateway", Path(r"D:\rustapp\ai-lib-gateway")),
]

KEY_PATH = Path.home() / ".ssh" / "id_ed25519_lan_git"
PUB_PATH = KEY_PATH.with_suffix(".pub")


def ssh_run(client: paramiko.SSHClient, cmd: str) -> tuple[int, str, str]:
    _, stdout, stderr = client.exec_command(cmd)
    out = stdout.read().decode()
    err = stderr.read().decode()
    code = stdout.channel.recv_exit_status()
    return code, out, err


def ensure_local_key() -> str:
    KEY_PATH.parent.mkdir(parents=True, exist_ok=True)
    if not KEY_PATH.exists():
        subprocess.run(
            [
                "ssh-keygen",
                "-t",
                "ed25519",
                "-f",
                str(KEY_PATH),
                "-N",
                "",
                "-C",
                f"{USER}@{HOST}",
            ],
            check=True,
        )
        print(f"Generated SSH key: {KEY_PATH}")
    return PUB_PATH.read_text(encoding="utf-8").strip()


def ensure_authorized_key(client: paramiko.SSHClient, pubkey: str) -> None:
    _, out, _ = ssh_run(client, f"test -f ~/.ssh/authorized_keys && cat ~/.ssh/authorized_keys || true")
    if pubkey.split()[1] in out:
        print("SSH public key already authorized on server")
        return
    cmd = (
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && "
        f"echo '{pubkey}' >> ~/.ssh/authorized_keys && "
        "chmod 600 ~/.ssh/authorized_keys"
    )
    code, _, err = ssh_run(client, cmd)
    if code != 0:
        raise RuntimeError(f"Failed to install authorized key: {err}")
    print("Installed SSH public key on git server")


def ensure_bare_repo(client: paramiko.SSHClient, name: str) -> None:
    path = f"{REPO_ROOT}/{name}.git"
    cmd = (
        f"mkdir -p {REPO_ROOT} && "
        f"if [ ! -d '{path}' ]; then git init --bare '{path}'; echo CREATED; else echo EXISTS; fi"
    )
    code, out, err = ssh_run(client, cmd)
    if code != 0:
        raise RuntimeError(f"Failed to init bare repo {name}: {err}")
    print(f"  {name}: {out.strip()}")


def git_remote_url(name: str) -> str:
    return f"ssh://{USER}@{HOST}{REPO_ROOT}/{name}.git"


def setup_remote_and_push(local: Path, name: str, push_all: bool = False) -> None:
    if not (local / ".git").exists():
        print(f"  SKIP {name}: not a git repo")
        return

    result = subprocess.run(
        ["git", "-C", str(local), "rev-parse", "--abbrev-ref", "HEAD"],
        text=True,
        capture_output=True,
    )
    if result.returncode != 0 or result.stdout.strip() in ("", "HEAD"):
        print(f"  SKIP {name}: no commits yet")
        return
    branch = result.stdout.strip()

    remote = "lan"
    url = git_remote_url(name)
    subprocess.run(["git", "-C", str(local), "remote", "remove", remote], capture_output=True)
    subprocess.run(["git", "-C", str(local), "remote", "add", remote, url], check=True)

    env = os.environ.copy()
    env["GIT_SSH_COMMAND"] = (
        f'ssh -i "{KEY_PATH}" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no'
    )

    push_ref = "--all" if push_all else branch
    push_args = ["git", "-C", str(local), "push"]
    if push_all:
        push_args.extend(["--all", remote])
    else:
        push_args.extend(["-u", remote, branch])

    print(f"  pushing {name} ({push_ref}) -> {url}")
    result = subprocess.run(
        push_args,
        env=env,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        print(f"  PUSH FAILED: {result.stderr.strip() or result.stdout.strip()}")
    else:
        print(f"  PUSH OK: {result.stderr.strip() or result.stdout.strip()}")


def main() -> int:
    pubkey = ensure_local_key()

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(HOST, username=USER, password=PASSWORD, timeout=15)

    ensure_authorized_key(client, pubkey)

    print("\nBare repos on server:")
    for name, _ in PRIVATE_REPOS:
        ensure_bare_repo(client, name)
    client.close()

    print("\nPush from local clones:")
    for name, path in PRIVATE_REPOS:
        print(f"\n[{name}]")
        setup_remote_and_push(path, name, push_all=(name == "eos"))

    return 0


if __name__ == "__main__":
    sys.exit(main())
