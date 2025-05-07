#!/bin/bash

# --- Functions ---

show_welcome() {
    clear  # Clear the screen for a clean look

    echo ""
    sleep 0.2
    echo " _   _      _ _          ____    _    __  __ ____           _ "
    sleep 0.2
    echo "| | | | ___| | | ___    / ___|  / \  |  \/  |  _ \ ___ _ __| |"
    sleep 0.2
    echo "| |_| |/ _ \ | |/ _ \  | |     / _ \ | |\/| | |_) / _ \ '__| |"
    sleep 0.2
    echo "|  _  |  __/ | | (_) | | |___ / ___ \| |  | |  __/  __/ |  |_|"
    sleep 0.2
    echo "|_| |_|\___|_|_|\___/   \____/_/   \_\_|  |_|_|   \___|_|  (_)"
    sleep 0.5

    echo ""
    echo "🌲🏕️      WELCOME TO CAMP SETUP! 🏕️    🌲"
    echo "===================================================="
    echo ""
    echo "   🏕️      Configuring Databases & Conda Environments"
    echo "       for CAMP Gene Catalog"
    echo ""
    echo "   🔥 Let's get everything set up properly!"
    echo ""
    echo "===================================================="
    echo ""

}

# Check to see if the base CAMP environment has already been installed 
find_install_camp_env() {
    if conda env list | grep -q "$DEFAULT_CONDA_ENV_DIR/camp"; then 
        echo "✅ The main CAMP environment is already installed in $DEFAULT_CONDA_ENV_DIR."
    else
        echo "🚀 Installing the main CAMP environment in $DEFAULT_CONDA_ENV_DIR/..."
        conda create --prefix "$DEFAULT_CONDA_ENV_DIR/camp" -c conda-forge -c bioconda biopython blast bowtie2 bumpversion click click-default-group cookiecutter jupyter matplotlib numpy pandas samtools scikit-learn scipy seaborn snakemake umap-learn upsetplot
        echo "✅ The main CAMP environment has been installed successfully!"
    fi
}

# Check to see if the required conda environments have already been installed 
find_install_conda_env() {
    if conda env list | grep -q "$DEFAULT_CONDA_ENV_DIR/$1"; then
        echo "✅ The $1 environment is already installed in $DEFAULT_CONDA_ENV_DIR."
    else
        echo "🚀 Installing $1 in $DEFAULT_CONDA_ENV_DIR/$1..."
        conda create --prefix $DEFAULT_CONDA_ENV_DIR/$1 -c conda-forge -c bioconda $1
        echo "✅ $1 installed successfully!"
}

# TODO will need to refactor at some point to standardize
# if [[ -d "$USER_PATH" && -d "$USER_PATH"/db/amrfinderplus-db ]]; then
#     BAKTA_DB_PATH="$USER_PATH/db"
#     echo "✅ Bakta DB path set to: $BAKTA_DB_PATH"
#     break
# else
#     echo "⚠️ That path does not appear to contain a valid Bakta DB (amrfinderplus-db missing)."
# fi

# Ask user if each database is already installed or needs to be installed
ask_database() {
    local DB_NAME="$1"
    local DB_VAR_NAME="$2"
    local DB_PATH=""

    echo "🛠️  Checking for $DB_NAME database..."

    while true; do
        read -p "❓ Do you already have $DB_NAME installed? (y/n): " RESPONSE
        case "$RESPONSE" in
            [Yy]* )
                while true; do
                    read -p "📂 Enter the path to your existing $DB_NAME database (eg. /path/to/database_storage): " DB_PATH
                    if [[ -d "$DB_PATH" || -f "$DB_PATH" ]]; then
                        DATABASE_PATHS[$DB_VAR_NAME]="$DB_PATH"
                        echo "✅ $DB_NAME path set to: $DB_PATH"
                        return  # Exit the function immediately after successful input
                    else
                        echo "⚠️ The provided path does not exist or is empty. Please check and try again."
                        read -p "Do you want to re-enter the path (r) or install $DB_NAME instead (i)? (r/i): " RETRY
                        if [[ "$RETRY" == "i" ]]; then
                            break  # Exit inner loop to start installation
                        fi
                    fi
                done
                if [[ "$RETRY" == "i" ]]; then
                    break  # Exit outer loop to install the database
                fi
                ;;
            [Nn]* )
                read -p "📂 Enter the directory where you want to install $DB_NAME: " DB_PATH
                install_database "$DB_NAME" "$DB_VAR_NAME" "$DB_PATH"
                return  # Exit function after installation
                ;;
            * ) echo "⚠️ Please enter 'y(es)' or 'n(o)'.";;
        esac
    done
}

# Install databases in the specified directory
install_database() {
    local DB_NAME="$1"
    local DB_VAR_NAME="$2"
    local INSTALL_DIR="$3"
    local FINAL_DB_PATH="$INSTALL_DIR/${DB_SUBDIRS[$DB_VAR_NAME]}"

    echo "🚀 Installing $DB_NAME database in: $FINAL_DB_PATH"	

    case "$DB_VAR_NAME" in
        "bakta")
            conda activate bakta 
            BAKTA_DB_PATH="$INSTALL_BASE/bakta_db"
            echo "📡 Downloading Bakta DB to $BAKTA_DB_PATH..."
            bakta_db download --output "$BAKTA_DB_PATH" --type full
            conda deactivate
            FINAL_DB_PATH="$BAKTA_DB_PATH/db"
            echo "✅ Bakta database installed successfully!"
            ;;
        "DATABASE_2_PATH")
            wget https://repository2.com/database_2.tar.gz -P $INSTALL_DIR
	        mkdir -p $FINAL_DB_PATH
            tar -xzf "$INSTALL_DIR/database_2.tar.gz" -C "$FINAL_DB_PATH"
            echo "✅ Database 2 installed successfully!"
            ;;
        *)
            echo "⚠️ Unknown database: $DB_NAME"
            ;;
    esac

    DATABASE_PATHS[$DB_VAR_NAME]="$FINAL_DB_PATH"
}

# --- Initialize setup ---

show_welcome

# Set work_dir
MODULE_WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PATH=$PWD
read -p "Enter the working directory (Press Enter for default: $DEFAULT_PATH): " USER_WORK_DIR
GENE_CATALOG_WORK_DIR="$(realpath "${USER_WORK_DIR:-$PWD}")"
echo "Working directory set to: $GENE_CATALOG_WORK_DIR"
#echo "export ${GENE_CATALOG_WORK_DIR} >> ~/.bashrc"

# --- Install conda environments ---

cd $MODULE_WORK_DIR
DEFAULT_CONDA_ENV_DIR=$(conda info --base)/envs

# Find or install...

# ...module environment
find_install_camp_env

# Function to check and install conda environments
check_and_install_env() {
    ENV_NAME=$1
    CONFIG_PATH=$2

    if conda env list | grep -q "$DEFAULT_CONDA_ENV_DIR/$ENV_NAME"; then
        echo "✅ Conda environment $ENV_NAME already exists."
    else
        echo "Installing Conda environment $ENV_NAME from $CONFIG_PATH..."
        CONDA_CHANNEL_PRIORITY=flexible conda env create -f "$CONFIG_PATH" || { echo "❌ Failed to install $ENV_NAME."; return; }
    fi
}

# ...auxiliary environments
MODULE_PKGS=('bakta') # Add any additional conda packages here
for m in "${MODULE_PKGS[@]}"; do
    find_install_conda_env "$m"
done

# --- Download databases ---

# Default database locations relative to $INSTALL_DIR
declare -A DB_SUBDIRS=(
    ["bakta"]="bakta_db/db"
)

# Absolute database paths (to be set in install_database)
declare -A DATABASE_PATHS

# Ask for all required databases
ask_database "Bakta" "bakta"

# --- Generate parameter configs ---

# Default values for analysis parameters
EXT_PATH="$MODULE_WORK_DIR/workflow/ext"  # Assuming extensions are in workflow/ext

# Use existing paths from DATABASE_PATHS
BAKTA_DB_PATH="${DATABASE_PATHS[bakta]}"

echo "🚀 Generating parameter configs ..."

# Create test_data/parameters.yaml
PARAMS_FILE="$MODULE_WORK_DIR/test_data/parameters.yaml" 
# Remove existing parameters.yaml if present
[ -f "$PARAMS_FILE" ] && rm "$PARAMS_FILE"

cat <<EOF > "$PARAMS_FILE"
#'''Parameters config.'''#


ext: '$EXT_PATH'
conda_prefix: '$DEFAULT_CONDA_ENV_DIR'


# --- call_orfs --- #

bakta_db: '$BAKTA_DB_PATH'


# --- cluster_orfs --- #

mmseqs_mode: easy-cluster # choose easy-cluster or easy-linclust for larger gene catalogs
cluster_percent_identity: 0.3
min_cluster_coverage: 0.9


# --- filter_gene_catalog --- #

min_gene_prevalence: 1


# --- run_alignments --- #

diamond_blocksize: 6
EOF

echo "✅ parameters.yaml file created successfully in test_data/"

# Create configs/parameters.yaml 
PARAMS_FILE="$MODULE_WORK_DIR/configs/parameters.yaml"
# Remove existing parameters.yaml if present
[ -f "$PARAMS_FILE" ] && rm "$PARAMS_FILE"

cat <<EOF > "$PARAMS_FILE"
#'''Parameters config.'''#


ext: '$EXT_PATH'
conda_prefix: '$DEFAULT_CONDA_ENV_DIR'


# --- call_orfs --- #

bakta_db: '$BAKTA_DB_PATH/db'


# --- cluster_orfs --- #

mmseqs_mode: easy-cluster # choose easy-cluster or easy-linclust for larger gene catalogs
cluster_percent_identity: 0.3
min_cluster_coverage: 0.9


# --- filter_gene_catalog --- #

min_gene_prevalence: 1


# --- run_alignments --- #

diamond_blocksize: 6
EOF

echo "✅ parameters.yaml file created successfully in configs/"

# Modify test_data/samples.csv
sed -i.bak "s|/path/to/camp_gene-catalog|$MODULE_WORK_DIR|g" $MODULE_WORK_DIR/test_data/samples.csv

echo "✅ samples.csv successfully created in test_data/"

echo "🎯 Setup complete! You can now test the workflow using \`python workflow/gene_catalog.py test\`"
