# IRS Labs - ARGoS Simulations
**Author**
- Dotti Andrea [[_Github profile_](https://github.com/AndreaD002)][[_Institutional_ _email_](mailto:andrea.dotti4@studio.unibo.it)]


This workspace contains several ARGoS robot-simulation experiments. To run them, you need ARGoS installed on your machine.

The recommended setup is:
- Linux (preferred for local execution)
- Docker (recommended if you want a clean, reproducible environment)

## Requirements

These labs use ARGoS `.argos` scenario files together with Lua controllers. You will need:
- ARGoS installed and available on your PATH
- A Linux environment or Docker container
- The required dependencies for ARGoS on your system

## Option 1: Run on Linux

Install ARGoS on a Linux machine, ideally Ubuntu or a Debian-based distribution. The usual workflow is:

1. Install the dependencies required by ARGoS.
2. Download and build ARGoS from the official project sources.
3. Verify the installation with:

```bash
argos3 --help
```

Then run a simulation from one of the lab folders, for example:

```bash
cd lab_activity-2
argos3 -c run-controller.argos
```

Similar commands can be used for the other folders:
- `lab_activity-3/test-subs.argos`
- `lab_activity-4/test-ms.argos`
- `lab_activity-5/test-controller-nn.argos`
- `lab_activity-6/test-aggregation.argos`

## Option 2: Run with Docker

If you do not want to install ARGoS directly on your host machine, use Docker with a Linux-based image that includes ARGoS.

Example workflow:

```bash
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  ubuntu:22.04 bash
```

Inside the container, install the required system packages and ARGoS, then run the simulations as usual.

> In short: ARGoS is required to execute these experiments, and Linux or Docker are the preferred ways to run them.

## Notes

- The repository includes experiment files such as `.argos` and Lua controller scripts.
- If ARGoS is not installed, the simulations will not run.
- Official installation instructions may vary slightly depending on the ARGoS version and operating system.
