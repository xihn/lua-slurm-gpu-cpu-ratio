# lua-slurm-ratio
Slurm job-submit plugin to enforce a gpu/cpu ratio, written in lua.


Ratios are calculated per card so that a given node is not over or under allocated for cpu/gpu. For instance a node with 4x GPUs and 32x CPU Cores should only accept jobs with less than or equal to of 8.0 CPU cores per GPU. Since we cant (not that I know of) predict which node a job will land on ratios have to be preset for each GPU. For example `H100` nodes have 8X H100 GPUS and 112x CPU cores for a ratio of 14.0. Thus if a job is submitted with `gpu=H100:1, ncpu=14` it will be allowed.

### Installation

- To build this, first ensure slurm has been built with lua enabled. This requires
the `lua` package and `lua-devel` package to be installed before `./configure` is ran.


- After simply place `job_submit.lua` in the same directory as `slurm.conf` (usually `/etc/slurm`). Then
modify `slurm.conf` to have `JobSubmitPlugins=lua`. Other plugins can come before or after ex, `JobSubmitPlugins=lua,plugin1,plugin2,`

### Configuring

- To customize simply edit the `.lua` file and reload `slurmctld`.
    - `enabled` is used to disable the plugin completely, passing in `slurm.SUCCESS` without having to reload slurmctld. Should be disabled via removing from `JobSubmitPlugins=` in `slurm.conf`
    - `card_ratios` is a map of GPU names to their ratios. The gpu names are case insensitive and should match their names in `gres.conf`
        - Ratios can be easily configured using [node-gres-info.sh](/node-gres-info/node-gres-info.sh) which prints the different configurations of nodes.
    - `default_ratio` is the fallback ratio for cards that are not defined in `card_ratios`


### Testing
- Naive tests can be done via lua's busted testing framework. To run tests simply run `busted` in the root directory of the project. This will run all tests in the `spec` directory.
- For actual comprehensive testing either run on a testbed with different node configurations, or you can use the experimental [slurm-docker]() repo to test on a dockerized slurm cluster.


### TODO

- Modify to work on multiple partitions
- Non-uniform nodes. Ex some nodes with the same GPUs but less CPU cores
- Add more tests
