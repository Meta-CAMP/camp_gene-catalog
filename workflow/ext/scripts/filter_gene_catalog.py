import argparse
from collections import Counter
from os.path import abspath, basename, join
import pandas as pd


def ingest_fasta(f_in):
    seqs = {}
    name = 'NA'
    seq = 'NA'
    with open(f_in, 'r') as fi:
        for l in fi:
            if '>' in l:
                seqs[name] = seq
                name = l[1:].split()[0].strip()
                seq = ''
            else:
                seq += l.strip()
    seqs[name] = seq
    del seqs['NA']
    return seqs


def main(args):
    clusters = []
    with open(args.clst) as f:
        for l in f:
            clusters.append(l.rstrip().split('\t'))
    congenes = [x[0] for x in clusters]
    size_df = pd.DataFrame.from_dict(Counter(congenes),orient='index', columns = ['cluster_size'])
    # size_df['sample'] = [x.split('_')[0] for x in size_df.index]
    size_df.to_csv(join(args.out_dir, 'merged_cluster_sizes.csv'))
    clst_to_keep = size_df[size_df['cluster_size']>=int(args.min_prev)].index
    seqs = ingest_fasta(str(args.fasta))
    with open(join(args.out_dir, 'merged_filt_seq.fasta'),'w') as fo:
        for i in clst_to_keep:
            fo.write('>' + i + '\n')
            fo.write(seqs[i] + '\n')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("fasta", help="Gene cluster sequences")
    parser.add_argument("clst", help="Gene clustering")    
    parser.add_argument("out_dir", help="Output directory")
    parser.add_argument("min_prev", help="Minimum prevalence of gene cluster across samples to be considered")
    args = parser.parse_args()
    main(args)
