# CAMP Gene Catalog

[![Documentation Status](https://img.shields.io/readthedocs/camp-gene_catalog)](https://camp-documentation.readthedocs.io/en/latest/gene_catalog.html) ![Version](https://img.shields.io/badge/version-0.2.0-brightgreen)

## Overview

This module is designed to function as both a standalone gene catalog pipeline as well as a component of the larger CAMP metagenome analysis pipeline. As such, it is both self-contained (ex. instructions included for the setup of a versioned environment, etc.), and seamlessly compatible with other CAMP modules (ex. ingests and spawns standardized input/output config files, etc.). 

This module generates and functionally annotates a gene catalog from assembled contigs. It is both self-contained (ex. instructions included for the setup of a versioned environment, etc.), and compatible with other CAMP modules (ex. ingests and spawns standardized input/output config files, etc.). 

## Approach

<INSERT PIPELINE IMAGE>

## Installation

1. Clone repo from [Github](<https://github.com/MetaSUB-CAMP/camp_gene-catalog>).
```Bash
git clone https://github.com/MetaSUB-CAMP/camp_gene-catalog
```

2. Set up the conda environment using `configs/conda/gene-catalog.yaml`. 
```Bash
# Create and activate conda environment 
cd camp_gene-catalog
conda env create -f configs/conda/gene-catalog.yaml
conda activate gene-catalog
```

3. After activating the conda environment, download the Bakta databases to a directory of your choosing. Make sure you update the `parameters.yaml` file with its location. Use absolute (not relative) paths when downloading the Bakta databases.
```Bash
bakta_db download --output /path/to/bakta/db
amrfinder_update --database /path/to/bakta/db/amrfinderplus-db
```

4. Update the parameters `ext` and `bakta_db` in `test_data/parameters.yaml`.

5. Make sure the installed pipeline works correctly. With 40 threads and a maximum of 80 GB allocated, the test dataset should finish in approximately 43 minutes.
```Bash
# Run tests on the included sample dataset
python /path/to/camp_gene-catalog/workflow/gene-catalog.py test
```

## Using the Module

**Input**: `/path/to/samples.csv` provided by the user.

**Output**: TODO

- `/path/to/work/dir/short_read_qc/final_reports/samples.csv` for ingestion by the next module

### Module Structure
```
└── workflow
    ├── Snakefile
    ├── gene-catalog.py
    ├── utils.py
    ├── __init__.py
    └── ext/
        └── scripts/
```
- `workflow/gene-catalog.py`: Click-based CLI that wraps the `snakemake` and other commands for clean management of parameters, resources, and environment variables.
- `workflow/Snakefile`: The `snakemake` pipeline. 
- `workflow/utils.py`: Sample ingestion and work directory setup functions, and other utility functions used in the pipeline and the CLI.
- `ext/`: External programs, scripts, and small auxiliary files that are not conda-compatible but used in the workflow.

### Running the Workflow

1. Make your own `samples.csv` based on the template in `configs/samples.csv`. Sample test data can be found in `test_data/`. 
    - `samples.csv` requires either absolute paths or paths relative to the directory that the module is being run in

2. Update the relevant parameters in `configs/parameters.yaml`.

3. Update the computational resources available to the pipeline in `configs/resources.yaml`. 

#### Command Line Deployment

To run CAMP on the command line, use the following, where `/path/to/work/dir` is replaced with the absolute path of your chosen working directory, and `/path/to/samples.csv` is replaced with your copy of `samples.csv`. 
    - The default number of cores available to Snakemake is 1 which is enough for test data, but should probably be adjusted to 10+ for a real dataset.
    - Relative or absolute paths to the Snakefile and/or the working directory (if you're running elsewhere) are accepted!
    - The parameters and resource config YAMLs can also be customized.
```Bash
python /path/to/camp_gene-catalog/workflow/gene-catalog.py \
    (-c number_of_cores_allocated) \
    (-p /path/to/parameters.yaml) \
    (-r /path/to/resources.yaml) \
    -d /path/to/work/dir \
    -s /path/to/samples.csv
```

#### Slurm Cluster Deployment

To run CAMP on a job submission cluster (for now, only Slurm is supported), use the following.
    - `--slurm` is an optional flag that submits all rules in the Snakemake pipeline as `sbatch` jobs. 
    - In Slurm mode, the `-c` flag refers to the maximum number of `sbatch` jobs submitted in parallel, **not** the pool of cores available to run the jobs. Each job will request the number of cores specified by threads in `configs/resources/slurm.yaml`.
```Bash
sbatch -J jobname -o jobname.log << "EOF"
#!/bin/bash
python /path/to/camp_gene-catalog/workflow/gene-catalog.py --slurm \
    (-c max_number_of_parallel_jobs_submitted) \
    (-p /path/to/parameters.yaml) \
    (-r /path/to/resources.yaml) \
    -d /path/to/work/dir \
    -s /path/to/samples.csv
EOF
```

## Credits

- This package was created with [Cookiecutter](https://github.com/cookiecutter/cookiecutter>) as a simplified version of the [project template](https://github.com/audreyr/cookiecutter-pypackage>).
- Free software: MIT
- Documentation: https://camp-documentation.readthedocs.io/en/latest/gene-catalog.html

