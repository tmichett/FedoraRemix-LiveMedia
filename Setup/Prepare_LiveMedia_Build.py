#!/usr/bin/env python3
"""Prepare a Fedora system for live ISO builds using livemedia-creator (lorax)."""

import os
import subprocess
import shutil
import sys


def run_command(command, shell=False):
    """Run a shell command and return the output"""
    print(f"Running command: {command}")
    try:
        if shell:
            result = subprocess.run(command, shell=True, check=True, text=True, capture_output=True)
        else:
            result = subprocess.run(command, check=True, text=True, capture_output=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        print(f"Command output: {e.stdout}")
        print(f"Error output: {e.stderr}")
        sys.exit(1)


def is_root():
    """Check if the script is running as root"""
    return os.geteuid() == 0


def ensure_root():
    """Ensure the script is running as root"""
    if not is_root():
        print("This script must be run as root. Please use sudo.")
        sys.exit(1)


def fedora_major_version():
    """Return Fedora major version id from /etc/os-release, or None if unknown."""
    try:
        with open("/etc/os-release", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("VERSION_ID="):
                    raw = line.split("=", 1)[1].strip().strip('"')
                    return int(float(raw))
    except (OSError, ValueError):
        pass
    return None


def install_packages(packages):
    """Install packages using dnf"""
    print(f"Installing packages: {', '.join(packages)}")
    run_command(["dnf", "install", "-y"] + packages)


def create_directory(path, mode=0o755):
    """Create a directory with specified permissions"""
    if not os.path.exists(path):
        print(f"Creating directory {path}")
        os.makedirs(path, mode=mode)
    else:
        print(f"Directory {path} already exists")


def synchronize_files(src, dest):
    """Synchronize files using rsync with sudo"""
    print(f"Synchronizing {src} to {dest}")
    if not os.path.exists(src):
        print(f"Warning: Source directory {src} does not exist")
        return

    cmd = ["sudo", "rsync", "-avz", src, dest]
    run_command(cmd)


def copy_file(src, dest, mode=None):
    """Copy a file from source to destination with optional permissions"""
    print(f"Copying {src} to {dest}")
    if not os.path.exists(src):
        print(f"Warning: Source file {src} does not exist")
        return

    dest_dir = os.path.dirname(dest)
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)

    shutil.copy2(src, dest)

    if mode is not None:
        os.chmod(dest, mode)


def main():
    """Set up the system and populate /livemedia-creator/FedoraRemix for livemedia-creator."""
    ensure_root()

    # lorax provides livemedia-creator; anaconda is required on PATH for --no-virt installs
    major = fedora_major_version()
    # pykickstart provides ksflatten (resolve %include before livemedia-creator / anaconda)
    remix_packages = ["vim", "lorax", "pykickstart", "anaconda", "sshfs"]
    if major is not None and major >= 42:
        remix_packages.append("util-linux-script")

    livemedia_root = "/livemedia-creator/FedoraRemix"
    lmc_tmp = "/livemedia-creator/tmp"
    remix_directories = [livemedia_root, lmc_tmp]

    install_packages(remix_packages)

    for directory in remix_directories:
        create_directory(directory, mode=0o755)
    os.chmod(lmc_tmp, 0o755)

    kickstart_src = "./Kickstarts/"
    if os.path.exists(kickstart_src):
        synchronize_files(kickstart_src, livemedia_root + "/")
    else:
        print(f"Warning: Kickstarts directory not found at {kickstart_src}")

    copy_file("./Prepare_LiveMedia_Build.py", f"{livemedia_root}/Prepare_LiveMedia_Build.py")
    copy_file("./Prepare_Web_Files.py", f"{livemedia_root}/Prepare_Web_Files.py")
    ymls = [
        "Prepare_Fedora_Remix_Build.yml",
        "Prepare_Web_Files.yml",
    ]
    for yf in ymls:
        path = f"./{yf}"
        if os.path.exists(path):
            copy_file(path, f"{livemedia_root}/{yf}")

    exec_mode = 0o755
    copy_file("./LiveMedia_Enhanced_Build_Script.sh", f"{livemedia_root}/LiveMedia_Enhanced_Build_Script.sh", exec_mode)
    copy_file("./Remix_Build_Script.sh", f"{livemedia_root}/Remix_Build_Script.sh", exec_mode)
    copy_file("./config.yml", f"{livemedia_root}/config.yml")

    print("Setup complete.")
    print(f"Files copied to {livemedia_root}:")
    print("  - Kickstart files and snippets")
    print("  - Prepare_LiveMedia_Build.py, Prepare_Web_Files.py")
    print("  - LiveMedia_Enhanced_Build_Script.sh (lorax / livemedia-creator; anaconda for --no-virt)")
    print("  - Remix_Build_Script.sh (minimal wrapper)")
    print("  - config.yml")
    print("")
    print("Build: sudo ./LiveMedia_Enhanced_Build_Script.sh  (in that directory, after prepare)")


if __name__ == "__main__":
    main()
