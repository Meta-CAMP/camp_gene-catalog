#!/bin/bash

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

show_welcome

# Set work_dir
DEFAULT_PATH=$PWD
read -p "Enter the working directory (Press Enter for default: $DEFAULT_PATH): " USER_WORK_DIR
GENE_CATALOG_WORK_DIR="$(realpath "${USER_WORK_DIR:-$PWD}")"
echo "Working directory set to: $GENE_CATALOG_WORK_DIR"
#echo "export ${GENE_CATALOG_WORK_DIR} >> ~/.bashrc"


# Install conda envs: dataviz, annotations (bakta)
cd $DEFAULT_PATH
DEFAULT_CONDA_ENV_DIR=$(conda info --base)/envs

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

echo "Checking conda environments ..."
# Check and install environments
check_and_install_env "bakta" "configs/conda/bakta_new.yaml"
check_and_install_env "dataviz" "configs/conda/dataviz.yaml"

while true; do
    read -p "❓ Do you already have the Bakta database installed? (y/n): " RESPONSE
    case "$RESPONSE" in
        [Yy]* )
            read -p "📂 Enter the full path to your existing Bakta database (e.g. /path/to/bakta_db): " USER_PATH
            if [[ -d "$USER_PATH" && -d "$USER_PATH"/db/amrfinderplus-db ]]; then
                BAKTA_DB_PATH="$USER_PATH/db"
                echo "✅ Bakta DB path set to: $BAKTA_DB_PATH"
                break
            else
                echo "⚠️ That path does not appear to contain a valid Bakta DB (amrfinderplus-db missing)."
            fi
            ;;
        [Nn]* )
            read -p "📁 Enter directory where you want to install the Bakta database [default: \$HOME/databases]: " INSTALL_BASE
            INSTALL_BASE="${INSTALL_BASE:-$HOME/databases}"
            BAKTA_DB_PATH="$INSTALL_BASE/bakta_db"
            mkdir -p "$BAKTA_DB_PATH"
            echo "📡 Downloading Bakta DB to $BAKTA_DB_PATH..."
            bakta_db download --output "$BAKTA_DB_PATH" --type full
            BAKTA_DB_PATH="$BAKTA_DB_PATH/db"
            echo "✅ Bakta DB downloaded successfully!"
           break
            ;;
        * )
            echo "⚠️ Please answer y or n."
            ;;
    esac
done

# Generate parameters.yaml
SCRIPT_DIR=$(pwd)
EXT_PATH="$DEFAULT_PATH/workflow/ext"
PARAMS_FILE="test_data/parameters.yaml"

# Remove existing parameters.yaml if present
[ -f "$PARAMS_FILE" ] && rm "$PARAMS_FILE"
# Create new parameters.yaml file
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

PARAMS_FILE="configs/parameters.yaml"

# Remove existing parameters.yaml if present
[ -f "$PARAMS_FILE" ] && rm "$PARAMS_FILE"
# Create new parameters.yaml file
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

echo "✅ parameters.yaml file created successfully in test_data/"

# Modify test_data/samples.csv
sed -i.bak "s|/path/to/camp_gene-catalog|$DEFAULT_PATH|g" test_data/samples.csv

echo "✅ samples.csv successfully created in test_data/"

echo "🎯 Setup complete! You can now test the workflow using \`python workflow/gene_catalog.py test\`"
