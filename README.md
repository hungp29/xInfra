# xInfra

xInfra is a simple toolkit for setting up a local [MicroK8s](https://microk8s.io/) environment using shell scripts.

## Usage

- **Setup MicroK8s:**
  ```sh
  ./setup.sh
  ```

- **Test the environment:**
  ```sh
  ./test.sh
  ```

- **Clean up resources:**
  ```sh
  ./clean.sh
  ```

## Requirements

- Linux environment
- Bash shell
- [MicroK8s](https://microk8s.io/) (will be installed by `setup.sh` if not present)

## Notes

- Run all scripts with sufficient permissions (e.g., `sudo` if required).
- Scripts are intended for local development and testing purposes only.
